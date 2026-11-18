module semantic_pure_validation
    ! Validates PURE/ELEMENTAL procedure bodies per F2008 C1283.
    ! A PURE procedure must not perform external I/O (PRINT, WRITE to an
    ! external unit, READ) or execute an image-control / program-halting
    ! statement such as STOP or PAUSE. ELEMENTAL implies PURE, so the same
    ! body restrictions apply.
    use ast_arena_modern, only: ast_arena_t
    use ast_types, only: LITERAL_INTEGER
    use ast_nodes_core, only: assignment_node, identifier_node, call_or_subscript_node, &
        literal_node, binary_op_node
    use ast_nodes_io, only: print_statement_node, write_statement_node, &
        read_statement_node
    use ast_nodes_data, only: declaration_node, parameter_declaration_node
    use ast_nodes_misc, only: interface_block_node, module_procedure_node
    use ast_nodes_transfer, only: stop_node, pause_node
    use ast_nodes_loops, only: do_loop_node, do_while_node
    use ast_nodes_conditional, only: if_node
    use ast_nodes_associate, only: block_construct_node
    use ast_nodes_procedure, only: subroutine_call_node, function_def_node, &
        subroutine_def_node
    use error_handling, only: error_collection_t, ERROR_SEMANTIC
    use semantic_pure_dummy_validation, only: validate_pure_dummies
    use frontend_compiler_resolution, only: declaration_binding_t, &
        resolve_name_at_node, find_enclosing_scope, ASSOCIATION_DIRECT, BINDING_DECLARATION, &
        BINDING_DUMMY_ARGUMENT
    use string_utils_mod, only: int_to_string, to_lower
    implicit none
    private

    public :: validate_pure_procedure, is_pure_prefix
    public :: validate_do_concurrent_purity

    ! F2008 13.1: MVBITS and MOVE_ALLOC are the only PURE intrinsic
    ! subroutines. Coarray and atomic intrinsics are deliberately left out of
    ! this list; they belong to a different diagnostic family.
    integer, parameter :: IMPURE_INTRINSIC_NAME_LEN = 24
    character(len=IMPURE_INTRINSIC_NAME_LEN), parameter :: &
        IMPURE_INTRINSIC_SUBROUTINES(11) = [ &
        character(len=IMPURE_INTRINSIC_NAME_LEN) :: &
        'cpu_time', 'date_and_time', 'execute_command_line', 'get_command', &
        'get_command_argument', 'getcwd', 'get_environment_variable', 'random_init', &
        'random_number', 'random_seed', 'system_clock']

contains

    ! Returns .true. when the prefix list marks the procedure as PURE,
    ! either explicitly (pure) or implicitly (elemental). An explicit
    ! impure keyword overrides elemental.
    function is_pure_prefix(prefix_keywords) result(is_pure)
        character(len=*), allocatable, intent(in) :: prefix_keywords(:)
        logical :: is_pure
        logical :: has_pure, has_elemental, has_impure
        integer :: i

        is_pure = .false.
        if (.not. allocated(prefix_keywords)) return

        has_pure = .false.
        has_elemental = .false.
        has_impure = .false.
        do i = 1, size(prefix_keywords)
            select case (trim(prefix_keywords(i)))
            case ('pure', 'simple')
                has_pure = .true.
            case ('elemental')
                has_elemental = .true.
            case ('impure')
                has_impure = .true.
            end select
        end do

        if (has_impure) return
        is_pure = has_pure .or. has_elemental
    end function is_pure_prefix

    ! Validate a procedure body when its prefix marks it PURE/ELEMENTAL.
    ! Non-pure procedures are accepted unchanged.
    subroutine validate_pure_procedure(arena, body_indices, prefix_keywords, &
            errors, param_indices, is_function)
        type(ast_arena_t), intent(in) :: arena
        integer, allocatable, intent(in) :: body_indices(:)
        character(len=*), allocatable, intent(in) :: prefix_keywords(:)
        type(error_collection_t), intent(inout) :: errors
        integer, allocatable, intent(in), optional :: param_indices(:)
        logical, intent(in), optional :: is_function
        logical :: function_context

        if (.not. is_pure_prefix(prefix_keywords)) return

        if (present(param_indices)) then
            function_context = .false.
            if (present(is_function)) function_context = is_function
            call validate_pure_dummies(arena, param_indices, body_indices, &
                function_context, errors)
        end if

        if (.not. allocated(body_indices)) return

        call check_pure_body(arena, body_indices, errors, param_indices)
    end subroutine validate_pure_procedure

    ! F2008 8.1.6.5: the body of a DO CONCURRENT construct is a pure context,
    ! so it may not reference an impure intrinsic subroutine.
    recursive subroutine validate_do_concurrent_purity(arena, body_indices, errors)
        type(ast_arena_t), intent(in) :: arena
        integer, allocatable, intent(in) :: body_indices(:)
        type(error_collection_t), intent(inout) :: errors
        integer :: i

        if (.not. allocated(body_indices)) return
        do i = 1, size(body_indices)
            if (.not. arena%has_node_at(body_indices(i))) cycle
            call check_concurrent_statement(arena, body_indices(i), errors)
        end do
    end subroutine validate_do_concurrent_purity

    recursive subroutine check_concurrent_statement(arena, stmt_index, errors)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: stmt_index
        type(error_collection_t), intent(inout) :: errors
        integer :: i

        select type (stmt => arena%entries(stmt_index)%node)
            type is (subroutine_call_node)
            call check_concurrent_call(arena, stmt, errors)
            type is (block_construct_node)
            call validate_do_concurrent_purity(arena, stmt%body_indices, errors)
            type is (do_loop_node)
            call validate_do_concurrent_purity(arena, stmt%body_indices, errors)
            type is (do_while_node)
            call validate_do_concurrent_purity(arena, stmt%body_indices, errors)
            type is (if_node)
            call validate_do_concurrent_purity(arena, stmt%then_body_indices, &
                errors)
            if (allocated(stmt%elseif_blocks)) then
                do i = 1, size(stmt%elseif_blocks)
                    call validate_do_concurrent_purity(arena, &
                        stmt%elseif_blocks(i)%body_indices, errors)
                end do
            end if
            call validate_do_concurrent_purity(arena, stmt%else_body_indices, &
                errors)
        end select
    end subroutine check_concurrent_statement

    ! F2018 C1141: a reference to an impure procedure shall not appear in a
    ! DO CONCURRENT construct.
    subroutine check_concurrent_call(arena, stmt, errors)
        type(ast_arena_t), intent(in) :: arena
        type(subroutine_call_node), intent(in) :: stmt
        type(error_collection_t), intent(inout) :: errors
        integer :: def_index

        if (.not. allocated(stmt%name)) return

        if (is_impure_intrinsic_subroutine(stmt%name)) then
            if (.not. procedure_defined_in_arena(arena, stmt%name)) then
                call report_concurrent_call(errors, 'impure intrinsic '// &
                    'subroutine "'//trim(stmt%name)//'"', stmt%line, stmt%column)
                return
            end if
        end if

        def_index = find_subroutine_definition(arena, stmt%name)
        if (def_index <= 0) return
        select type (def => arena%entries(def_index)%node)
            type is (subroutine_def_node)
            if (is_pure_prefix(def%prefix_keywords)) return
            call report_concurrent_call(errors, 'Subroutine call to impure "'// &
                trim(stmt%name)//'"', stmt%line, stmt%column)
        end select
    end subroutine check_concurrent_call

    subroutine report_concurrent_call(errors, subject, line, column)
        type(error_collection_t), intent(inout) :: errors
        character(len=*), intent(in) :: subject
        integer, intent(in) :: line, column

        call errors%add_error( &
            message=subject//' is not allowed in a DO CONCURRENT construct', &
            code=ERROR_SEMANTIC, &
            component='semantic_pure_validation', &
            context='line '//int_to_string(line)//', column '// &
            int_to_string(column), &
            suggestion='move the impure call outside the DO CONCURRENT '// &
            'construct, declare the procedure PURE, or use an ordinary DO loop', &
            line=line, column=column, end_line=line, end_column=column + 1)
    end subroutine report_concurrent_call

    ! Arena index of a subroutine definition with this name, or 0.
    function find_subroutine_definition(arena, name) result(def_index)
        type(ast_arena_t), intent(in) :: arena
        character(len=*), intent(in) :: name
        integer :: def_index
        character(len=:), allocatable :: lowered
        integer :: i

        def_index = 0
        lowered = to_lower(trim(name))
        if (len_trim(lowered) == 0) return
        do i = 1, arena%size
            if (.not. arena%has_node_at(i)) cycle
            select type (node => arena%entries(i)%node)
                type is (subroutine_def_node)
                if (.not. allocated(node%name)) cycle
                if (to_lower(trim(node%name)) == lowered) then
                    def_index = i
                    return
                end if
            end select
        end do
    end function find_subroutine_definition

    function is_impure_intrinsic_subroutine(name) result(is_impure)
        character(len=*), intent(in) :: name
        logical :: is_impure
        character(len=:), allocatable :: lowered
        integer :: i

        is_impure = .false.
        lowered = to_lower(trim(name))
        do i = 1, size(IMPURE_INTRINSIC_SUBROUTINES)
            if (trim(IMPURE_INTRINSIC_SUBROUTINES(i)) == lowered) then
                is_impure = .true.
                return
            end if
        end do
    end function is_impure_intrinsic_subroutine

    ! A user procedure of the same name shadows the intrinsic, so the call is
    ! not an intrinsic reference and this rule does not apply.
    function procedure_defined_in_arena(arena, name) result(is_defined)
        type(ast_arena_t), intent(in) :: arena
        character(len=*), intent(in) :: name
        logical :: is_defined
        character(len=:), allocatable :: lowered
        integer :: i

        is_defined = .false.
        lowered = to_lower(trim(name))
        do i = 1, arena%size
            if (.not. arena%has_node_at(i)) cycle
            select type (node => arena%entries(i)%node)
                type is (subroutine_def_node)
                if (.not. allocated(node%name)) cycle
                if (to_lower(trim(node%name)) == lowered) then
                    is_defined = .true.
                    return
                end if
                type is (function_def_node)
                if (.not. allocated(node%name)) cycle
                if (to_lower(trim(node%name)) == lowered) then
                    is_defined = .true.
                    return
                end if
            end select
        end do
    end function procedure_defined_in_arena

    ! Recursively scan a list of body statements for prohibited statements.
    recursive subroutine check_pure_body(arena, body_indices, errors, &
            param_indices)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: body_indices(:)
        type(error_collection_t), intent(inout) :: errors
        integer, allocatable, intent(in), optional :: param_indices(:)
        integer :: i, stmt_index

        do i = 1, size(body_indices)
            stmt_index = body_indices(i)
            if (.not. arena%has_node_at(stmt_index)) cycle
            call check_pure_statement(arena, stmt_index, errors, param_indices)
        end do
    end subroutine check_pure_body

    ! Inspect a single statement: report it if prohibited, recurse into the
    ! bodies of nested control-flow constructs otherwise.
    recursive subroutine check_pure_statement(arena, stmt_index, errors, &
            param_indices)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: stmt_index
        type(error_collection_t), intent(inout) :: errors
        integer, allocatable, intent(in), optional :: param_indices(:)

        select type (stmt => arena%entries(stmt_index)%node)
            type is (print_statement_node)
            call report_impure_stmt(errors, 'PRINT', stmt%line, stmt%column)
            type is (write_statement_node)
            if (.not. is_local_internal_write(arena, stmt_index, stmt)) &
                call report_impure_stmt(errors, 'WRITE', stmt%line, stmt%column)
            type is (read_statement_node)
            if (.not. is_local_internal_element_read(arena, stmt_index, stmt)) &
                call report_impure_stmt(errors, 'READ', stmt%line, stmt%column)
            type is (stop_node)
            call report_impure_stmt(errors, 'STOP', stmt%line, stmt%column)
            type is (pause_node)
            call report_impure_stmt(errors, 'PAUSE', stmt%line, stmt%column)
            type is (assignment_node)
            if (defined_assignment_is_impure(arena) .and. &
                targets_derived_dummy(arena, stmt, param_indices)) then
                call report_impure_stmt(errors, 'defined assignment', &
                    stmt%line, stmt%column)
            end if
            type is (if_node)
            call check_pure_if(arena, stmt, errors, param_indices)
            type is (do_loop_node)
            if (allocated(stmt%body_indices)) &
                call check_pure_body(arena, stmt%body_indices, errors, &
                    param_indices)
            type is (do_while_node)
            if (allocated(stmt%body_indices)) &
                call check_pure_body(arena, stmt%body_indices, errors, &
                    param_indices)
        end select
    end subroutine check_pure_statement

    ! Classify only a directly declared local CHARACTER array element as an
    ! internal input file. This is an external-I/O purity classification, not
    ! acceptance of the READ: the interpreter IR and producer binding guards
    ! still validate index effects, control specifiers, targets and IOSTAT.
    logical function is_local_internal_element_read(arena, stmt_index, stmt) result(local)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: stmt_index
        type(read_statement_node), intent(in) :: stmt
        type(declaration_binding_t) :: binding
        character(len=:), allocatable :: error_msg, type_name, base_name
        integer :: scope, expression_index, rank, j
        integer :: marks(arena%size)
        local = .false.
        scope = find_enclosing_scope(arena, stmt_index)
        if (.not. arena%has_node_at(scope)) return
        select type (proc => arena%entries(scope)%node)
        type is (function_def_node)
        type is (subroutine_def_node)
        class default
            return
        end select

        if (.not. allocated(stmt%specifiers)) return
        if (size(stmt%specifiers) < 2 .or. size(stmt%specifiers) > 3) return
        if (.not. stmt%is_formatted) return
        if (stmt%err_label_index /= 0 .or. stmt%end_label_index /= 0 .or. &
            stmt%format_expr_index /= 0) return
        if (allocated(stmt%namelist_group)) then
            if (len_trim(stmt%namelist_group) > 0) return
        end if
        if (.not. allocated(stmt%unit_spec) .or. .not. allocated(stmt%format_spec)) return
        if (stmt%format_spec /= '*') return
        do j = 1, size(stmt%specifiers)
            if (.not. allocated(stmt%specifiers(j)%name)) return
            if (.not. allocated(stmt%specifiers(j)%value)) return
        end do
        if (to_lower(stmt%specifiers(1)%name) /= 'unit') return
        if (stmt%specifiers(1)%value /= stmt%unit_spec) return
        if (to_lower(stmt%specifiers(2)%name) /= 'fmt') return
        if (stmt%specifiers(2)%value /= '*') return
        if (size(stmt%specifiers) == 3) then
            if (to_lower(stmt%specifiers(3)%name) /= 'iostat') return
            if (.not. arena%has_node_at(stmt%specifiers(3)%value_node_index)) return
            select type (status => arena%entries(stmt%specifiers(3)%value_node_index)%node)
            type is (identifier_node)
                if (.not. writable_identifier(stmt%specifiers(3)%value_node_index, .true.)) return
            class default
                return
            end select
        else if (stmt%iostat_var_index /= 0) then
            return
        end if
        if (.not. allocated(stmt%var_indices)) return
        do j = 1, size(stmt%var_indices)
            if (.not. arena%has_node_at(stmt%var_indices(j))) return
            select type (target => arena%entries(stmt%var_indices(j))%node)
            type is (identifier_node)
                if (.not. writable_identifier(stmt%var_indices(j), .false.)) return
            class default
                return
            end select
        end do
        expression_index = stmt%specifiers(1)%value_node_index
        if (.not. arena%has_node_at(expression_index)) return
        select type (file => arena%entries(expression_index)%node)
        type is (call_or_subscript_node)
            if (.not. allocated(file%name)) return
            if (.not. allocated(file%arg_indices)) return
            rank = size(file%arg_indices)
            if (rank < 1 .or. rank > 3) return
            base_name = file%name
        class default
            return
        end select
        call resolve_name_at_node(arena, stmt_index, base_name, binding, error_msg)
        if (.not. binding%found) return
        if (binding%binding_kind /= BINDING_DECLARATION) return
        if (binding%association /= ASSOCIATION_DIRECT .or. &
            binding%scope_node_index /= scope) return
        if (.not. arena%has_node_at(binding%declaration_node_index)) return
        select type (decl => arena%entries(binding%declaration_node_index)%node)
        type is (declaration_node)
            if (.not. allocated(decl%type_name)) return
            type_name = to_lower(trim(decl%type_name))
            if (len(type_name) < 9) return
            if (type_name(:9) /= 'character') return
            if (len(type_name) > 9) then
                if (type_name(10:10) /= '(' .and. type_name(10:10) /= '*') return
            end if
            if (.not. decl%is_array) return
            if (.not. allocated(decl%dimension_indices)) return
            if (size(decl%dimension_indices) /= rank) return
            if (decl%is_parameter .or. decl%is_save .or. decl%has_initializer .or. &
                decl%is_pointer .or. decl%is_external .or. decl%is_protected .or. &
                decl%is_volatile .or. decl%has_intent .or. decl%is_optional) return
            marks = 0
        select type (file => arena%entries(expression_index)%node)
        type is (call_or_subscript_node)
            if (file%base_expr_index /= 0) return
            do j = 1, rank
                if (.not. scalar_index(file%arg_indices(j), 0)) return
            end do
        end select
        local = .true.
        end select
    contains
        logical function writable_identifier(index, status) result(writable)
            integer, intent(in) :: index
            logical, intent(in) :: status
            type(declaration_binding_t) :: target_binding
            character(len=:), allocatable :: target_error, target_name, intent_name, intrinsic_type
            integer :: delimiter
            writable = .false.
            if (.not. arena%has_node_at(index)) return
            select type (node => arena%entries(index)%node)
            type is (identifier_node)
                if (.not. allocated(node%name)) return
                target_name = node%name
            class default
                return
            end select
            call resolve_name_at_node(arena, stmt_index, target_name, target_binding, target_error)
            if (.not. target_binding%found) return
            if (target_binding%association /= ASSOCIATION_DIRECT .or. &
                target_binding%scope_node_index /= scope) return
            if (target_binding%binding_kind /= BINDING_DECLARATION .and. &
                target_binding%binding_kind /= BINDING_DUMMY_ARGUMENT) return
            if (.not. arena%has_node_at(target_binding%declaration_node_index)) return
            select type (decl => arena%entries(target_binding%declaration_node_index)%node)
            type is (declaration_node)
                if (.not. allocated(decl%type_name)) return
                intrinsic_type = to_lower(trim(decl%type_name))
                delimiter = scan(intrinsic_type, '(*')
                if (delimiter > 0) intrinsic_type = intrinsic_type(:delimiter-1)
                intrinsic_type = trim(intrinsic_type)
                if (status) then
                    if (intrinsic_type /= 'integer') return
                else
                    select case (intrinsic_type)
                    case ('integer', 'real', 'character')
                    case default
                        return
                    end select
                end if
                if (decl%is_array .or. decl%is_parameter .or. decl%is_save .or. &
                    decl%has_initializer .or. decl%is_pointer .or. decl%is_allocatable .or. &
                    decl%is_external .or. decl%is_protected .or. decl%is_volatile .or. &
                    decl%is_optional) return
                if (decl%has_intent) then
                    if (.not. allocated(decl%intent)) return
                    intent_name = to_lower(trim(decl%intent))
                    if (intent_name /= 'out' .and. intent_name /= 'inout') return
                    select type (proc => arena%entries(scope)%node)
                    type is (function_def_node)
                        return
                    end select
                else if (target_binding%binding_kind == BINDING_DUMMY_ARGUMENT) then
                    return
                end if
            class default
                ! An incomplete parameter declaration cannot prove writable storage.
                return
            end select
            writable = .true.
        end function writable_identifier
        recursive logical function scalar_index(index, depth) result(valid)
            integer, intent(in) :: index, depth
            type(declaration_binding_t) :: index_binding
            integer :: suffix
            character(len=:), allocatable :: index_error, integer_type
            valid = .false.
            if (depth > 256 .or. index < 1 .or. index > size(marks)) return
            if (.not. arena%has_node_at(index)) return
            if (marks(index) == 1) return
            if (marks(index) == 2) then
                valid = .true.
                return
            end if
            marks(index) = 1
            select type (node => arena%entries(index)%node)
            type is (literal_node)
                if (node%literal_kind /= LITERAL_INTEGER) return
                if (allocated(node%literal_type)) then
                    if (to_lower(node%literal_type) /= 'integer') return
                end if
                if (.not. allocated(node%value)) return
                if (len(node%value) == 0) return
                ! Integer literal spelling, with optional numeric/named KIND.
                ! Unary signs have separate binary AST nodes (synthetic zero).
                suffix = scan(node%value, '_')
                if (suffix == 0) then
                    if (verify(node%value, '0123456789') /= 0) return
                else
                    if (suffix == 1 .or. suffix == len(node%value)) return
                    if (verify(node%value(:suffix-1), '0123456789') /= 0) return
                    if (verify(node%value(suffix+1:), '0123456789') /= 0) then
                        if (verify(node%value(suffix+1:suffix+1), &
                            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ') /= 0) return
                        if (verify(node%value(suffix+1:), &
                            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_') /= 0) return
                    end if
                end if
            type is (identifier_node)
                if (.not. allocated(node%name)) return
                call resolve_name_at_node(arena, stmt_index, node%name, index_binding, index_error)
                if (.not. index_binding%found) return
                if (index_binding%association /= ASSOCIATION_DIRECT .or. &
                    index_binding%scope_node_index /= scope .or. &
                    index_binding%binding_kind /= BINDING_DECLARATION) return
                if (.not. arena%has_node_at(index_binding%declaration_node_index)) return
                select type (decl => arena%entries(index_binding%declaration_node_index)%node)
                type is (declaration_node)
                    if (.not. allocated(decl%type_name)) return
                    integer_type = to_lower(trim(decl%type_name))
                    if (len(integer_type) < 7) return
                    if (integer_type(:7) /= 'integer') return
                    if (len(integer_type) > 7) then
                        if (integer_type(8:8) /= '(' .and. integer_type(8:8) /= '*') return
                    end if
                    if (decl%is_array .or. decl%is_pointer .or. decl%is_allocatable .or. &
                        decl%has_intent .or. decl%is_optional .or. decl%is_external) return
                class default
                    return
                end select
            type is (binary_op_node)
                if (.not. allocated(node%operator)) return
                select case (trim(node%operator))
                case ('+', '-', '*', '/', '**')
                case default
                    return
                end select
                if (.not. scalar_index(node%left_index, depth + 1)) return
                if (.not. scalar_index(node%right_index, depth + 1)) return
            class default
                return
            end select
            marks(index) = 2
            valid = .true.
        end function scalar_index
    end function is_local_internal_element_read

    ! A local CHARACTER internal file is not an external I/O effect. Keep
    ! this exemption bounded to a whole scalar writable object declared in
    ! the current procedure; host/use association and external units fail
    ! closed. The separate dummy/purity validators retain their checks.
    logical function is_local_internal_write(arena, stmt_index, stmt) result(local)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: stmt_index
        type(write_statement_node), intent(in) :: stmt
        type(declaration_binding_t) :: binding
        character(len=:), allocatable :: error_msg, type_name, intent_name
        integer :: scope

        local = .false.
        if (.not. stmt%is_formatted .or. .not. allocated(stmt%unit_spec)) return
        scope = find_enclosing_scope(arena, stmt_index)
        if (.not. arena%has_node_at(scope)) return
        select type (proc => arena%entries(scope)%node)
        type is (function_def_node)
        type is (subroutine_def_node)
        class default
            return
        end select
        call resolve_name_at_node(arena, stmt_index, stmt%unit_spec, binding, error_msg)
        if (.not. binding%found) return
        if (binding%association /= ASSOCIATION_DIRECT .or. &
            binding%scope_node_index /= scope) return
        if (.not. arena%has_node_at(binding%declaration_node_index)) return
        select type (decl => arena%entries(binding%declaration_node_index)%node)
        type is (declaration_node)
            if (.not. allocated(decl%type_name)) return
            type_name = to_lower(trim(decl%type_name))
            if (len(type_name) < 9) return
            if (type_name(:9) /= 'character') return
            if (len(type_name) > 9) then
                if (type_name(10:10) /= '(' .and. type_name(10:10) /= '*') return
            end if
            if (decl%is_array .or. decl%is_parameter .or. decl%is_save .or. &
                decl%has_initializer .or. decl%is_pointer .or. decl%is_external .or. &
                decl%is_protected .or. decl%is_volatile) return
            if (decl%has_intent) then
                if (.not. allocated(decl%intent)) return
                intent_name = to_lower(trim(decl%intent))
                if (intent_name /= 'out' .and. intent_name /= 'inout') return
            end if
            local = .true.
        end select
    end function is_local_internal_write

    ! Recurse into all branches of an IF construct.
    recursive subroutine check_pure_if(arena, node, errors, param_indices)
        type(ast_arena_t), intent(in) :: arena
        type(if_node), intent(in) :: node
        type(error_collection_t), intent(inout) :: errors
        integer, allocatable, intent(in), optional :: param_indices(:)
        integer :: i

        if (allocated(node%then_body_indices)) &
            call check_pure_body(arena, node%then_body_indices, errors, &
                param_indices)
        if (allocated(node%elseif_blocks)) then
            do i = 1, size(node%elseif_blocks)
                if (allocated(node%elseif_blocks(i)%body_indices)) &
                    call check_pure_body(arena, &
                    node%elseif_blocks(i)%body_indices, errors, param_indices)
            end do
        end if
        if (allocated(node%else_body_indices)) &
            call check_pure_body(arena, node%else_body_indices, errors, &
                param_indices)
    end subroutine check_pure_if

    ! A defined assignment is impure unless its resolved procedure is PURE.
    ! Limit this check to a derived-type dummy target so intrinsic assignment
    ! remains valid in a PURE procedure when an unrelated overload exists.
    logical function targets_derived_dummy(arena, assignment, param_indices) &
        result(matches)
        type(ast_arena_t), intent(in) :: arena
        type(assignment_node), intent(in) :: assignment
        integer, allocatable, intent(in), optional :: param_indices(:)
        character(len=:), allocatable :: name, lowered
        integer :: i

        matches = .false.
        if (.not. present(param_indices)) return
        if (.not. allocated(param_indices)) return
        if (.not. arena%has_node_at(assignment%target_index)) return

        select type (target => arena%entries(assignment%target_index)%node)
            type is (identifier_node)
            if (.not. allocated(target%name)) return
            name = to_lower(trim(target%name))
            do i = 1, size(param_indices)
                if (.not. arena%has_node_at(param_indices(i))) cycle
                select type (param => arena%entries(param_indices(i))%node)
                    type is (declaration_node)
                    if (.not. allocated(param%var_name)) cycle
                    if (to_lower(trim(param%var_name)) /= name) cycle
                    if (.not. allocated(param%type_name)) return
                    lowered = to_lower(trim(param%type_name))
                    matches = index(lowered, 'type(') == 1 .or. &
                        index(lowered, 'class(') == 1
                    return
                    type is (parameter_declaration_node)
                    if (.not. allocated(param%name)) cycle
                    if (to_lower(trim(param%name)) /= name) cycle
                    if (.not. allocated(param%type_name)) return
                    lowered = to_lower(trim(param%type_name))
                    matches = index(lowered, 'type(') == 1 .or. &
                        index(lowered, 'class(') == 1
                    return
                end select
            end do
        end select
    end function targets_derived_dummy

    logical function defined_assignment_is_impure(arena) result(is_impure)
        type(ast_arena_t), intent(in) :: arena
        integer :: i, j, k
        character(len=:), allocatable :: kind

        is_impure = .false.
        do i = 1, arena%size
            if (.not. arena%has_node_at(i)) cycle
            select type (iface => arena%entries(i)%node)
                type is (interface_block_node)
                if (.not. allocated(iface%kind)) cycle
                kind = to_lower(trim(iface%kind))
                if (kind /= 'assignment') cycle
                if (.not. allocated(iface%procedure_indices)) cycle
                do j = 1, size(iface%procedure_indices)
                    if (.not. arena%has_node_at(iface%procedure_indices(j))) cycle
                    select type (proc => &
                            arena%entries(iface%procedure_indices(j))%node)
                        type is (module_procedure_node)
                        if (.not. allocated(proc%procedure_names)) cycle
                        do k = 1, size(proc%procedure_names)
                            if (procedure_name_is_impure(arena, &
                                proc%procedure_names(k)%s)) then
                                is_impure = .true.
                                return
                            end if
                        end do
                        type is (function_def_node)
                        if (.not. is_pure_prefix(proc%prefix_keywords)) then
                            is_impure = .true.
                            return
                        end if
                        type is (subroutine_def_node)
                        if (.not. is_pure_prefix(proc%prefix_keywords)) then
                            is_impure = .true.
                            return
                        end if
                    end select
                end do
            end select
        end do
    end function defined_assignment_is_impure

    logical function procedure_name_is_impure(arena, name) result(is_impure)
        type(ast_arena_t), intent(in) :: arena
        character(len=*), intent(in) :: name
        integer :: i
        character(len=:), allocatable :: lowered

        is_impure = .false.
        lowered = to_lower(trim(name))
        do i = 1, arena%size
            if (.not. arena%has_node_at(i)) cycle
            select type (proc => arena%entries(i)%node)
                type is (function_def_node)
                if (.not. allocated(proc%name)) cycle
                if (to_lower(trim(proc%name)) /= lowered) cycle
                is_impure = .not. is_pure_prefix(proc%prefix_keywords)
                return
                type is (subroutine_def_node)
                if (.not. allocated(proc%name)) cycle
                if (to_lower(trim(proc%name)) /= lowered) cycle
                is_impure = .not. is_pure_prefix(proc%prefix_keywords)
                return
            end select
        end do
    end function procedure_name_is_impure

    subroutine report_impure_stmt(errors, kind, line, column)
        type(error_collection_t), intent(inout) :: errors
        character(len=*), intent(in) :: kind
        integer, intent(in) :: line, column

        call errors%add_error( &
            message=kind//' statement is not allowed in a PURE procedure', &
            code=ERROR_SEMANTIC, &
            component='semantic_pure_validation', &
            context='line '//int_to_string(line)//', column '// &
            int_to_string(column), &
            suggestion='remove the I/O or control statement, or drop the '// &
            'PURE/ELEMENTAL prefix', line=line, column=column, end_line=line, &
            end_column=column + 1)
    end subroutine report_impure_stmt

end module semantic_pure_validation
