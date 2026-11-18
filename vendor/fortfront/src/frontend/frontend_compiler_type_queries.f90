module frontend_compiler_type_queries
    use ast_arena_modern, only: ast_arena_t
    use ast_base, only: ast_node, string_t, LITERAL_INTEGER, LITERAL_REAL, &
        LITERAL_STRING, LITERAL_LOGICAL
    use ast_nodes_core, only: literal_node, identifier_node, binary_op_node, &
        call_or_subscript_node, component_access_node, assignment_node, array_literal_node
    use ast_nodes_loops, only: do_loop_node
    use semantic_implied_do_validation, only: is_array_constructor_implied_do
    use ast_nodes_bounds, only: array_slice_node, range_expression_node, array_bounds_node
    use ast_nodes_data, only: declaration_node, parameter_declaration_node, &
        derived_type_node, module_node
    use ast_nodes_misc, only: complex_literal_node, use_statement_node, interface_block_node, module_procedure_node, &
        visibility_statement_node
    use ast_nodes_procedure, only: function_def_node
    use frontend_compiler_resolution, only: declaration_binding_t, &
        resolve_name_at_node, resolve_identifier_binding, BINDING_DERIVED_TYPE, &
        resolve_name_in_scope, find_enclosing_scope, find_host_scope, BINDING_FUNCTION, BINDING_GENERIC_INTERFACE, &
        get_scope_statement_indices, BINDING_INTRINSIC_ARRAY
    use string_utils_mod, only: to_lower
    use type_system_unified, only: mono_type_t, create_mono_type, TINT, TREAL, TCHAR, &
        TLOGICAL, TARRAY, TCOMPLEX, TDOUBLE, TDERIVED
    use semantic_elemental_validation, only: is_elemental_prefix
    use semantic_input_mode, only: INPUT_MODE_LAZY
    use standardizer_parameter, only: get_standardizer_input_mode
    implicit none
    private

    type, public :: resolved_type_query_t
        logical :: found = .false.
        integer :: type_kind = 0
        integer :: kind_value = 0
        integer :: storage_size_bits = 0
        integer :: rank = -1
        character(len=:), allocatable :: derived_type_name
        type(declaration_binding_t) :: derived_type_binding
        character(len=:), allocatable :: diagnostic
    end type resolved_type_query_t

    public :: annotate_resolved_expression_types
    public :: query_resolved_type, resolve_expression_type
    ! Shared by strict argument checking before expression annotation runs.
    public :: resolve_kind_selector, resolve_kind_expression

contains

    subroutine annotate_resolved_expression_types(arena)
        type(ast_arena_t), intent(inout) :: arena
        logical, allocatable :: visiting(:)
        integer :: i

        if (arena%size <= 0) return
        allocate (visiting(arena%size), source=.false.)

        do i = 1, arena%size
            if (.not. arena%has_node_at(i)) cycle
            call clear_resolved_metadata(arena%entries(i)%node)
        end do

        do i = 1, arena%size
            if (.not. arena%has_node_at(i)) cycle
            call resolve_node_metadata(arena, i, visiting)
        end do
    end subroutine annotate_resolved_expression_types

    ! Strict argument validation runs before final whole-arena annotation. Use
    ! the same scope-aware resolver on demand, including complete expressions,
    ! so arithmetic/intrinsic actuals retain their declared element kind/rank.
    function resolve_expression_type(arena, node_index) result(query)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: node_index
        type(resolved_type_query_t) :: query
        logical, allocatable :: visiting(:)
        allocate (visiting(arena%size), source=.false.)
        call resolve_node_metadata(arena, node_index, visiting)
        query = query_resolved_type(arena, node_index)
    end function resolve_expression_type

    function query_resolved_type(arena, node_index) result(query)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: node_index
        type(resolved_type_query_t) :: query

        query%derived_type_name = ""
        query%derived_type_binding = declaration_binding_t()
        query%diagnostic = ""

        if (.not. arena%has_node_at(node_index)) then
            query%diagnostic = "node index does not reference an AST node"
            return
        end if

        associate (node => arena%entries(node_index)%node)
            query%type_kind = node%resolved_type_kind
            query%kind_value = node%resolved_kind_value
            query%storage_size_bits = node%resolved_storage_bits
            query%rank = node%resolved_rank
            query%derived_type_name = trim(node%resolved_derived_type_name)
            query%found = node%resolved_type_found
        end associate

        if (query%found .and. query%type_kind == TDERIVED .and. &
            len_trim(query%derived_type_name) > 0) then
            call resolve_name_at_node(arena, node_index, &
                query%derived_type_name, query%derived_type_binding, &
                query%diagnostic)
            if (query%derived_type_binding%binding_kind /= BINDING_DERIVED_TYPE) then
                query%derived_type_binding = declaration_binding_t()
                query%diagnostic = "derived type binding is unavailable"
            end if
        end if

        if (.not. query%found) then
            query%diagnostic = &
                "exact semantic type is unavailable for this AST node"
        end if
    end function query_resolved_type

    subroutine clear_resolved_metadata(node)
        class(ast_node), intent(inout) :: node

        node%resolved_type_found = .false.
        node%resolved_type_kind = 0
        node%resolved_kind_value = 0
        node%resolved_storage_bits = 0
        node%resolved_rank = -1
        node%resolved_derived_type_name = ""
    end subroutine clear_resolved_metadata

    recursive subroutine resolve_node_metadata(arena, node_index, visiting)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: node_index
        logical, intent(inout) :: visiting(:)

        if (node_index <= 0) return
        if (node_index > arena%size) return
        if (.not. arena%has_node_at(node_index)) return
        if (arena%entries(node_index)%node%resolved_type_found) return
        if (visiting(node_index)) return

        visiting(node_index) = .true.
        select type (node => arena%entries(node_index)%node)
            type is (literal_node)
            call resolve_literal(arena, node_index, node)
            type is (array_literal_node)
            call resolve_array_literal(arena, node_index, node, visiting)
            type is (do_loop_node)
            if (is_array_constructor_implied_do(arena, node_index)) then
                call resolve_constructor_loop(arena, node, visiting)
            else
                call resolve_from_inferred_type(node)
            end if
            type is (complex_literal_node)
            call resolve_complex_literal(arena, node, visiting)
            type is (declaration_node)
            call resolve_declaration(arena, node_index, node, visiting)
            type is (parameter_declaration_node)
            call resolve_parameter_declaration(arena, node_index, node)
            type is (identifier_node)
            call resolve_identifier(arena, node_index, node, visiting)
            type is (binary_op_node)
            call resolve_binary_operation(arena, node_index, node, visiting)
            type is (call_or_subscript_node)
            call resolve_call_or_subscript(arena, node_index, node, visiting)
            type is (assignment_node)
            if (node%is_keyword_argument) then
                call resolve_node_metadata(arena, node%value_index, visiting)
                call copy_metadata_from_index(arena, node%value_index, node)
            else
                call resolve_from_inferred_type(node)
            end if
            type is (array_slice_node)
            call resolve_array_slice(arena, node, visiting)
            type is (component_access_node)
            call resolve_component_access(arena, node_index, node, visiting)
            type is (function_def_node)
            call resolve_function_result(arena, node_index, node, visiting)
        class default
            call resolve_from_inferred_type(node)
        end select
        visiting(node_index) = .false.
    end subroutine resolve_node_metadata

    subroutine resolve_array_literal(arena, node_index, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: node_index
        type(array_literal_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        integer :: i, child, element_type, element_kind, opening
        character(len=:), allocatable :: spec, base, selector
        call resolve_from_inferred_type(node)
        if (allocated(node%type_spec)) then
            if (len_trim(node%type_spec) > 0) then
                ! Empty intrinsic constructors have no element from which to
                ! infer kind. Bind their explicit selector at this occurrence.
                ! Leave CHARACTER and nonempty constructors unchanged.
                if (.not. allocated(node%element_indices)) return
                if (size(node%element_indices) /= 0) return
                spec = compact_lower(node%type_spec)
                base = spec
                opening = index(spec, "(")
                if (opening > 0) base = spec(:opening - 1)
                select case (base)
                case ("integer"); element_type = TINT
                case ("real"); element_type = TREAL
                case ("logical"); element_type = TLOGICAL
                case default; return
                end select
                element_kind = 4
                if (opening > 0) then
                    if (spec(len(spec):) /= ")") then
                        call clear_resolved_metadata(node)
                        return
                    end if
                    selector = spec(opening + 1:len(spec) - 1)
                    if (index(selector, "kind=") == 1) selector = selector(6:)
                    element_kind = resolve_kind_selector(arena, node_index, selector)
                end if
                call set_intrinsic_metadata(node, element_type, element_kind, 1)
                return
            end if
        end if
        if (.not. allocated(node%element_indices)) return
        if (size(node%element_indices) == 0) return
        element_type = 0
        element_kind = 0
        do i = 1, size(node%element_indices)
            child = node%element_indices(i)
            if (.not. arena%has_node_at(child)) return
            call resolve_node_metadata(arena, child, visiting)
            if (.not. arena%entries(child)%node%resolved_type_found) return
            if (i == 1) then
                element_type = arena%entries(child)%node%resolved_type_kind
                element_kind = arena%entries(child)%node%resolved_kind_value
            else
                if (element_type /= arena%entries(child)%node%resolved_type_kind .or. &
                    element_kind /= arena%entries(child)%node%resolved_kind_value) return
            end if
        end do
        call set_intrinsic_metadata(node, element_type, element_kind, 1)
    end subroutine resolve_array_literal

    recursive subroutine resolve_constructor_loop(arena, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        type(do_loop_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        integer :: i, child, element_type, element_kind

        ! The executable-DO inference marker cannot supply constructor kind.
        ! Resolve every ordered body value, including nested implied-DOs and
        ! array-valued leaves, and retain its exact element type and kind.
        call clear_resolved_metadata(node)
        if (.not. allocated(node%body_indices)) return
        if (size(node%body_indices) == 0) return
        element_type = 0
        element_kind = 0
        do i = 1, size(node%body_indices)
            child = node%body_indices(i)
            if (.not. arena%has_node_at(child)) return
            call resolve_node_metadata(arena, child, visiting)
            if (.not. arena%entries(child)%node%resolved_type_found) return
            if (i == 1) then
                element_type = arena%entries(child)%node%resolved_type_kind
                element_kind = arena%entries(child)%node%resolved_kind_value
            else
                if (element_type /= arena%entries(child)%node%resolved_type_kind .or. &
                    element_kind /= arena%entries(child)%node%resolved_kind_value) return
            end if
        end do
        call set_intrinsic_metadata(node, element_type, element_kind, 1)
    end subroutine resolve_constructor_loop

    subroutine resolve_literal(arena, node_index, node)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: node_index
        type(literal_node), intent(inout) :: node
        character(len=:), allocatable :: selector
        character(len=:), allocatable :: raw_value
        logical :: has_selector
        integer :: kind_value

        raw_value = ""
        if (allocated(node%value)) raw_value = node%value
        select case (node%literal_kind)
        case (LITERAL_INTEGER)
            call literal_selector(raw_value, selector, has_selector)
            if (has_selector) then
                kind_value = resolve_kind_selector(arena, node_index, selector)
            else
                kind_value = 4
            end if
            call set_intrinsic_metadata(node, TINT, kind_value, 0)
        case (LITERAL_REAL)
            call literal_selector(raw_value, selector, has_selector)
            if (has_selector) then
                kind_value = resolve_kind_selector(arena, node_index, selector)
            else if (has_double_exponent(raw_value)) then
                kind_value = 8
            else
                kind_value = 4
            end if
            call set_intrinsic_metadata(node, TREAL, kind_value, 0)
        case (LITERAL_STRING)
            call set_intrinsic_metadata(node, TCHAR, 1, 0)
        case (LITERAL_LOGICAL)
            call literal_selector(raw_value, selector, has_selector)
            if (has_selector) then
                kind_value = resolve_kind_selector(arena, node_index, selector)
            else
                kind_value = 4
            end if
            call set_intrinsic_metadata(node, TLOGICAL, kind_value, 0)
        end select
    end subroutine resolve_literal

    subroutine resolve_complex_literal(arena, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        type(complex_literal_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        integer :: real_kind, imag_kind

        real_kind = 0
        imag_kind = 0
        if (node%real_index > 0) then
            call resolve_node_metadata(arena, node%real_index, visiting)
            if (arena%has_node_at(node%real_index)) then
                real_kind = arena%entries(node%real_index)%node%resolved_kind_value
            end if
        end if
        if (node%imag_index > 0) then
            call resolve_node_metadata(arena, node%imag_index, visiting)
            if (arena%has_node_at(node%imag_index)) then
                imag_kind = arena%entries(node%imag_index)%node%resolved_kind_value
            end if
        end if
        call set_intrinsic_metadata(node, TCOMPLEX, max(real_kind, imag_kind), 0)
    end subroutine resolve_complex_literal

    subroutine resolve_declaration(arena, node_index, node, visiting)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: node_index
        type(declaration_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        integer :: rank
        integer :: selected_kind

        if (.not. allocated(node%type_name)) then
            call resolve_from_inferred_type(node)
            return
        end if
        rank = 0
        if (node%is_array) then
            if (allocated(node%dimension_indices)) rank = size(node%dimension_indices)
        end if
        ! Local adapter fix: CHARACTER kind_value is legacy length storage.
        ! The explicit kind selector has its own expression index; do not
        ! interpret CHARACTER(LEN=8) as character kind 8.
        if (type_kind_from_spec(compact_lower(node%type_name)) == TCHAR) then
            selected_kind = 1
            if (node%kind_selector_index > 0) then
                call evaluate_integer_constant(arena, node%kind_selector_index, &
                    selected_kind, visiting)
            end if
            call set_intrinsic_metadata(node, TCHAR, selected_kind, rank)
            return
        end if
        call resolve_type_spec(arena, node_index, node%type_name, node%has_kind, &
            node%kind_value, rank, node)
        if (.not. node%resolved_type_found .and. node%kind_selector_index > 0) then
            selected_kind = 0
            call evaluate_integer_constant(arena, node%kind_selector_index, &
                selected_kind, visiting)
            if (selected_kind > 0) then
                call set_intrinsic_metadata(node, &
                    type_kind_from_spec(compact_lower(node%type_name)), &
                    selected_kind, rank)
            end if
        end if
    end subroutine resolve_declaration

    subroutine resolve_parameter_declaration(arena, node_index, node)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: node_index
        type(parameter_declaration_node), intent(inout) :: node
        integer :: rank

        if (.not. allocated(node%type_name)) then
            call resolve_from_inferred_type(node)
            return
        end if
        rank = 0
        if (node%is_array) then
            if (allocated(node%dimension_indices)) rank = size(node%dimension_indices)
        end if
        call resolve_type_spec(arena, node_index, node%type_name, node%has_kind, &
            node%kind_value, rank, node)
    end subroutine resolve_parameter_declaration

    subroutine resolve_identifier(arena, node_index, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: node_index
        type(identifier_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        type(declaration_binding_t) :: binding
        character(len=:), allocatable :: error_msg

        call resolve_identifier_binding(arena, node_index, binding, error_msg)
        if (binding%found) then
            if (binding%binding_kind == BINDING_INTRINSIC_ARRAY) then
                call set_intrinsic_metadata(node, TINT, 4, 1)
                return
            end if
            call resolve_node_metadata(arena, binding%declaration_node_index, visiting)
            call copy_metadata_from_index(arena, binding%declaration_node_index, node)
            if (node%resolved_type_found) return
        end if
        call resolve_from_inferred_type(node)
    end subroutine resolve_identifier

    recursive subroutine resolve_binary_operation(arena, node_index, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: node_index
        type(binary_op_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        integer :: left_type, right_type, left_kind, right_kind
        integer :: result_type, result_kind, result_rank
        character(len=:), allocatable :: operator

        left_type = 0
        right_type = 0
        left_kind = 0
        right_kind = 0
        result_rank = 0
        if (node%left_index > 0) then
            call resolve_node_metadata(arena, node%left_index, visiting)
            call get_metadata(arena, node%left_index, left_type, left_kind, &
                result_rank)
        end if
        if (node%right_index > 0) then
            call resolve_node_metadata(arena, node%right_index, visiting)
            call get_metadata(arena, node%right_index, right_type, right_kind, &
                result_rank)
        end if

        operator = ""
        if (allocated(node%operator)) operator = to_lower(trim(node%operator))
        if (len(operator) >= 3) then
            if (operator(1:1) == '.' .and. operator(len(operator):) == '.' .and. &
                .not. is_relational_operator(operator) .and. .not. is_logical_operator(operator)) then
                call resolve_defined_operator_result(arena, node_index, node, visiting)
                return
            end if
        end if
        ! Binary + has no intrinsic CHARACTER signature. Resolve its visible
        ! defined specific rather than inventing numeric/operand result metadata.
        ! Numeric + remains intrinsic and cannot be replaced by an interface.
        if (operator == '+' .and. node%left_index > 0 .and. node%right_index > 0) then
            if (left_type == TCHAR .or. right_type == TCHAR) then
                call resolve_defined_operator_result(arena, node_index, node, visiting)
                return
            end if
        end if
        if (is_relational_operator(operator)) then
            call set_intrinsic_metadata(node, TLOGICAL, 4, result_rank)
            return
        end if
        if (is_logical_operator(operator)) then
            result_kind = max(left_kind, right_kind)
            if (result_kind <= 0) result_kind = 4
            call set_intrinsic_metadata(node, TLOGICAL, result_kind, result_rank)
            return
        end if

        if (operator == "//" .and. left_type == TCHAR .and. right_type == TCHAR) then
            if (left_kind == right_kind .and. left_kind > 0) then
                call set_intrinsic_metadata(node, TCHAR, left_kind, result_rank)
            end if
            return
        end if

        if (node%is_unary_minus) then
            call copy_metadata_from_index(arena, node%right_index, node)
            return
        end if

        if (node%left_index <= 0) then
            if (node%right_index > 0) then
                call copy_metadata_from_index(arena, node%right_index, node)
            end if
            return
        end if
        if (node%right_index <= 0) then
            call copy_metadata_from_index(arena, node%left_index, node)
            return
        end if

        if (operator == "**" .and. right_type == TINT) then
            if (left_type == TREAL .or. left_type == TCOMPLEX) then
                call set_intrinsic_metadata(node, left_type, left_kind, result_rank)
                return
            end if
        end if

        result_type = numeric_result_type(left_type, right_type)
        result_kind = numeric_result_kind(result_type, left_type, left_kind, &
            right_type, right_kind)
        if (result_type > 0 .and. result_kind > 0) then
            call set_intrinsic_metadata(node, result_type, result_kind, result_rank)
        else
            call resolve_from_inferred_type(node)
        end if
    end subroutine resolve_binary_operation

    recursive subroutine resolve_array_slice(arena, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        type(array_slice_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        integer :: i, bound, rank

        call resolve_node_metadata(arena, node%array_index, visiting)
        call copy_metadata_from_index(arena, node%array_index, node)
        if (.not. node%resolved_type_found) return
        ! A scalar CHARACTER base is a substring even before semantic inference
        ! has set the lexical flag (notably inside CALL actual arguments).
        ! CHARACTER array sections still retain their declared nonzero rank.
        if (node%resolved_type_kind == TCHAR .and. node%resolved_rank == 0) return
        rank = 0
        do i = 1, node%num_dimensions
            bound = node%bounds_indices(i)
            if (.not. arena%has_node_at(bound)) cycle
            select type (triplet => arena%entries(bound)%node)
            type is (range_expression_node)
                rank = rank + 1
            type is (array_bounds_node)
                rank = rank + 1
            class default
                call resolve_node_metadata(arena, bound, visiting)
                if (arena%entries(bound)%node%resolved_type_found) then
                    if (arena%entries(bound)%node%resolved_type_kind == TINT .and. &
                        arena%entries(bound)%node%resolved_rank == 1) rank = rank + 1
                end if
            end select
        end do
        node%resolved_rank = rank
    end subroutine resolve_array_slice

    subroutine resolve_call_or_subscript(arena, node_index, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: node_index
        type(call_or_subscript_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        type(declaration_binding_t) :: binding
        character(len=:), allocatable :: error_msg
        integer :: i, arg_index, call_rank, inferred_rank, inferred_kind
        type(mono_type_t) :: call_type

        if (.not. allocated(node%name)) then
            call resolve_from_inferred_type(node)
            return
        end if

        call resolve_name_at_node(arena, node_index, node%name, binding, error_msg)
        if (binding%found) then
            if (binding%binding_kind == BINDING_INTRINSIC_ARRAY) then
                ! A rank-one intrinsic-module constant is data, never a
                ! procedure. Preserve rank only for a triplet/vector subscript.
                if (.not. allocated(node%arg_indices)) return
                if (size(node%arg_indices) /= 1) return
                arg_index = node%arg_indices(1)
                if (.not. arena%has_node_at(arg_index)) return
                call_rank = 0
                select type (subscript => arena%entries(arg_index)%node)
                type is (range_expression_node)
                    call_rank = 1
                type is (array_bounds_node)
                    call_rank = 1
                class default
                    call resolve_node_metadata(arena, arg_index, visiting)
                    if (.not. arena%entries(arg_index)%node%resolved_type_found) return
                    if (arena%entries(arg_index)%node%resolved_type_kind /= TINT) return
                    call_rank = arena%entries(arg_index)%node%resolved_rank
                    if (call_rank < 0 .or. call_rank > 1) return
                end select
                node%is_intrinsic = .false.
                node%is_array_access = .true.
                call set_intrinsic_metadata(node, TINT, 4, call_rank)
                return
            end if
            if (binding%binding_kind == BINDING_FUNCTION .or. &
                binding%binding_kind == BINDING_GENERIC_INTERFACE) then
                ! A declared procedure/generic owns the call identity, even if
                ! lexical intrinsic discovery marked the same spelling earlier.
                node%is_intrinsic = .false.
                node%is_array_access = .false.
            end if
            if (binding%binding_kind == BINDING_GENERIC_INTERFACE) then
                call resolve_named_generic_result(arena, binding%declaration_node_index, node, visiting)
                return
            end if
            call resolve_node_metadata(arena, binding%declaration_node_index, visiting)
            call copy_metadata_from_index(arena, binding%declaration_node_index, node)
            if (node%resolved_type_found) then
                select type (proc => arena%entries(binding%declaration_node_index)%node)
                type is (declaration_node)
                    ! A subscripted array reference has the scalar element type
                    ! unless triplets or vector subscripts preserve dimensions.
                    ! Copying the declaration rank would accept x(1) for x(:).
                    if (proc%is_array .and. allocated(node%arg_indices)) then
                        ! An explicit array declaration shadows a same-named
                        ! intrinsic. Keep call classification consistent with
                        ! the declaration identity already resolved above.
                        node%is_intrinsic = .false.
                        node%is_array_access = .true.
                        call_rank = 0
                        do i = 1, size(node%arg_indices)
                            arg_index = node%arg_indices(i)
                            if (.not. arena%has_node_at(arg_index)) cycle
                            select type (subscript => arena%entries(arg_index)%node)
                            type is (range_expression_node)
                                call_rank = call_rank + 1
                            type is (array_bounds_node)
                                call_rank = call_rank + 1
                            class default
                                call resolve_node_metadata(arena, arg_index, visiting)
                                if (arena%entries(arg_index)%node%resolved_rank > 0) &
                                    call_rank = call_rank + 1
                            end select
                        end do
                        node%resolved_rank = call_rank
                    end if
                type is (function_def_node)
                    if (is_elemental_prefix(proc%prefix_keywords)) then
                        ! Module procedure bodies may not have been visited by
                        ! generic inference. Derive each call's rank from its
                        ! scoped actual expressions, never from another call.
                        call_rank = 0
                        if (allocated(node%arg_indices)) then
                            do i = 1, size(node%arg_indices)
                                arg_index = node%arg_indices(i)
                                if (.not. arena%has_node_at(arg_index)) cycle
                                call resolve_node_metadata(arena, arg_index, visiting)
                                call_rank = max(call_rank, &
                                    arena%entries(arg_index)%node%resolved_rank)
                            end do
                        end if
                        node%resolved_rank = call_rank
                        inferred_kind = inferred_base_kind(node%inferred_type, inferred_rank)
                        if (inferred_rank /= call_rank .or. &
                            normalize_type_kind(inferred_kind) /= node%resolved_type_kind) then
                            call_type = create_mono_type(node%resolved_type_kind)
                            do i = 1, call_rank
                                call_type = create_mono_type(TARRAY, args=[call_type])
                            end do
                            node%inferred_type = call_type
                        end if
                    end if
                end select
                return
            end if
        end if

        if (node%is_intrinsic) then
            call resolve_intrinsic_call(arena, node, visiting)
            if (node%resolved_type_found) return
        end if
        call resolve_from_inferred_type(node)
    end subroutine resolve_call_or_subscript

    recursive subroutine resolve_defined_operator_result(arena, node_index, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: node_index
        type(binary_op_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        type(declaration_binding_t) :: binding
        integer, allocatable :: actuals(:), specifics(:)
        integer :: i, j, p, k, scope, winner, best, score, rank, actual_rank
        logical :: ambiguous, elemental, winning_elemental
        character(:), allocatable :: error_msg
        type(mono_type_t) :: result_type

        call clear_resolved_metadata(node)
        actuals = [integer ::]
        if (node%left_index > 0) actuals = [actuals, node%left_index]
        if (node%right_index > 0) actuals = [actuals, node%right_index]
        specifics = [integer ::]
        do i = 1, arena%size
            if (.not. arena%has_node_at(i)) cycle
            select type (iface => arena%entries(i)%node)
            type is (interface_block_node)
                if (.not. allocated(iface%kind) .or. .not. allocated(iface%operator)) cycle
                if (iface%kind /= 'operator') cycle
                if (to_lower(trim(iface%operator)) /= to_lower(trim(node%operator))) cycle
                if (.not. defined_interface_visible(arena, i, node_index, node%operator)) cycle
                if (.not. allocated(iface%procedure_indices)) return
                scope = find_enclosing_scope(arena, i)
                if (scope == i) scope = find_host_scope(arena, scope)
                do j = 1, size(iface%procedure_indices)
                    p = iface%procedure_indices(j)
                    if (.not. arena%has_node_at(p)) return
                    select type (specific => arena%entries(p)%node)
                    type is (module_procedure_node)
                        if (.not. allocated(specific%procedure_names)) return
                        do k = 1, size(specific%procedure_names)
                            call resolve_name_in_scope(arena, scope, specific%procedure_names(k)%s, binding, error_msg)
                            if (.not. binding%found .or. binding%binding_kind /= BINDING_FUNCTION) return
                            specifics = [specifics, binding%declaration_node_index]
                        end do
                    type is (function_def_node)
                        specifics = [specifics, p]
                    class default
                        return
                    end select
                end do
            end select
        end do
        winner = 0; best = -1; rank = 0; ambiguous = .false.; winning_elemental = .false.
        do i = 1, size(specifics)
            call match_named_generic_candidate(arena, specifics(i), actuals, visiting, score, actual_rank, elemental)
            if (score < 0 .or. score < best) cycle
            if (score == best) then
                ambiguous = .true.
            else
                winner = specifics(i); best = score; rank = actual_rank
                winning_elemental = elemental; ambiguous = .false.
            end if
        end do
        if (winner <= 0 .or. ambiguous) return
        call resolve_node_metadata(arena, winner, visiting)
        call copy_metadata_from_index(arena, winner, node)
        if (.not. node%resolved_type_found) return
        if (winning_elemental) node%resolved_rank = rank
        result_type = create_mono_type(node%resolved_type_kind)
        do i = 1, node%resolved_rank
            result_type = create_mono_type(TARRAY, args=[result_type])
        end do
        node%inferred_type = result_type
    end subroutine resolve_defined_operator_result

    logical function defined_interface_visible(arena, iface_index, node_index, operator) result(visible)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: iface_index, node_index
        character(*), intent(in) :: operator
        integer :: host, scope, i, j, module_index
        integer, allocatable :: statements(:)
        logical :: public_op, named, named_public
        character(:), allocatable :: module_name, spec
        visible = .false.
        module_index = find_enclosing_scope(arena, iface_index)
        if (module_index == iface_index) module_index = find_host_scope(arena, module_index)
        host = find_enclosing_scope(arena, node_index)
        scope = host
        do while (scope > 0)
            if (scope == module_index) then
                visible = .true.; return
            end if
            scope = find_host_scope(arena, scope)
        end do
        if (.not. arena%has_node_at(module_index)) return
        select type (module => arena%entries(module_index)%node)
        type is (module_node)
            if (.not. allocated(module%name)) return
            module_name = to_lower(module%name)
        class default
            return
        end select
        spec = 'operator('//to_lower(trim(operator))//')'
        public_op = .true.; named = .false.; named_public = .false.
        call get_scope_statement_indices(arena, module_index, statements)
        do i = 1, size(statements)
            if (.not. arena%has_node_at(statements(i))) cycle
            select type (access => arena%entries(statements(i))%node)
            type is (visibility_statement_node)
                if (.not. access%has_list) then
                    public_op = .not. access%is_private
                else if (allocated(access%names)) then
                    do j = 1, size(access%names)
                        if (to_lower(trim(access%names(j)%s)) /= spec) cycle
                        named = .true.; named_public = .not. access%is_private
                    end do
                end if
            end select
        end do
        if (named) public_op = named_public
        if (.not. public_op) return
        scope = host
        do while (scope > 0)
            call get_scope_statement_indices(arena, scope, statements)
            do i = 1, size(statements)
                if (.not. arena%has_node_at(statements(i))) cycle
                select type (use => arena%entries(statements(i))%node)
                type is (use_statement_node)
                    if (use%is_intrinsic .or. .not. allocated(use%module_name)) cycle
                    if (to_lower(use%module_name) /= module_name) cycle
                    if (.not. use%has_only) then
                        visible = .true.; return
                    end if
                    if (.not. allocated(use%only_list)) cycle
                    do j = 1, size(use%only_list)
                        if (to_lower(trim(use%only_list(j)%s)) /= spec) cycle
                        visible = .true.; return
                    end do
                end select
            end do
            scope = find_host_scope(arena, scope)
        end do
    end function defined_interface_visible

    recursive subroutine resolve_named_generic_result(arena, interface_index, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: interface_index
        type(call_or_subscript_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        type(declaration_binding_t) :: binding
        character(len=:), allocatable :: error_msg
        integer, allocatable :: specifics(:)
        integer :: scope, i, j, p, candidate, score, best, winner, rank, actual_rank
        integer :: inferred_kind, inferred_rank
        logical :: ambiguous, elemental, winning_elemental
        type(mono_type_t) :: result_type

        ! A generic interface has no single result type. Resolve each occurrence
        ! against its scoped specifics and declared actual types, never infer its
        ! kind or rank from an unrelated invocation or the generic name.
        call clear_resolved_metadata(node)
        scope = find_enclosing_scope(arena, interface_index)
        if (scope == interface_index) scope = find_host_scope(arena, scope)
        if (scope <= 0) return
        allocate(specifics(0))
        select type (iface => arena%entries(interface_index)%node)
        type is (interface_block_node)
            if (.not. allocated(iface%procedure_indices)) return
            do i = 1, size(iface%procedure_indices)
                p = iface%procedure_indices(i)
                if (.not. arena%has_node_at(p)) return
                select type (specific => arena%entries(p)%node)
                type is (module_procedure_node)
                    if (.not. allocated(specific%procedure_names)) return
                    do j = 1, size(specific%procedure_names)
                        call resolve_name_in_scope(arena, scope, specific%procedure_names(j)%s, binding, error_msg)
                        if (.not. binding%found .or. binding%binding_kind /= BINDING_FUNCTION) return
                        specifics = [specifics, binding%declaration_node_index]
                    end do
                type is (function_def_node)
                    specifics = [specifics, p]
                class default
                    return
                end select
            end do
        class default
            return
        end select
        winner = 0; best = -1; rank = 0; ambiguous = .false.; winning_elemental = .false.
        do i = 1, size(specifics)
            candidate = specifics(i)
            call match_named_generic_candidate(arena, candidate, node%arg_indices, visiting, score, actual_rank, elemental, &
                allow_optional=.true.)
            if (score < 0 .or. score < best) cycle
            if (score == best) then
                ambiguous = .true.
            else
                winner = candidate; best = score; rank = actual_rank
                winning_elemental = elemental; ambiguous = .false.
            end if
        end do
        if (ambiguous) return
        if (winner <= 0) then
            ! A function generic extends the intrinsic only when none of its
            ! source specifics match. Do not turn a declared specific or an
            ! ambiguous call into an intrinsic based on its spelling alone.
            if (to_lower(node%name) == "repeat") then
                if (matches_intrinsic_repeat(arena, node, visiting)) then
                    node%is_intrinsic = .true.
                    call resolve_intrinsic_call(arena, node, visiting)
                end if
            end if
            return
        end if
        call resolve_node_metadata(arena, winner, visiting)
        call copy_metadata_from_index(arena, winner, node)
        if (.not. node%resolved_type_found) return
        if (winning_elemental) then
            node%resolved_rank = rank
            inferred_kind = inferred_base_kind(node%inferred_type, inferred_rank)
            if (inferred_rank /= rank .or. normalize_type_kind(inferred_kind) /= node%resolved_type_kind) then
                result_type = create_mono_type(node%resolved_type_kind)
                do i = 1, rank
                    result_type = create_mono_type(TARRAY, args=[result_type])
                end do
                node%inferred_type = result_type
            end if
        end if
    end subroutine resolve_named_generic_result

    recursive logical function matches_intrinsic_repeat(arena, node, visiting) result(matches)
        type(ast_arena_t), intent(inout) :: arena
        type(call_or_subscript_node), intent(in) :: node
        logical, intent(inout) :: visiting(:)
        integer :: slots(2), j, k, argument
        logical :: seen_keyword
        character(:), allocatable :: keyword
        matches = .false.; slots = 0; seen_keyword = .false.
        if (.not. allocated(node%arg_indices)) return
        if (size(node%arg_indices) /= 2) return
        do j = 1, 2
            argument = node%arg_indices(j); k = j
            if (.not. arena%has_node_at(argument)) return
            select type (arg => arena%entries(argument)%node)
            type is (assignment_node)
                if (.not. arg%is_keyword_argument) return
                seen_keyword = .true.
                if (.not. arena%has_node_at(arg%target_index)) return
                select type (target => arena%entries(arg%target_index)%node)
                type is (identifier_node)
                    if (.not. allocated(target%name)) return
                    keyword = to_lower(target%name)
                class default
                    return
                end select
                select case (keyword)
                case ("string"); k = 1
                case ("ncopies"); k = 2
                case default; return
                end select
                argument = arg%value_index
            class default
                if (seen_keyword) return
            end select
            if (slots(k) /= 0) return
            slots(k) = argument
        end do
        do j = 1, 2
            argument = slots(j)
            if (.not. arena%has_node_at(argument)) return
            call resolve_node_metadata(arena, argument, visiting)
            if (.not. arena%entries(argument)%node%resolved_type_found) return
            if (arena%entries(argument)%node%resolved_rank /= 0) return
        end do
        if (arena%entries(slots(1))%node%resolved_type_kind /= TCHAR) return
        if (arena%entries(slots(1))%node%resolved_kind_value /= 1) return
        if (arena%entries(slots(2))%node%resolved_type_kind /= TINT) return
        matches = .true.
    end function matches_intrinsic_repeat

    recursive subroutine match_named_generic_candidate(arena, procedure_index, actuals, visiting, score, rank, elemental, allow_optional)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: procedure_index
        integer, allocatable, intent(in) :: actuals(:)
        logical, intent(inout) :: visiting(:)
        integer, intent(out) :: score, rank
        logical, intent(out) :: elemental
        logical, intent(in), optional :: allow_optional
        logical, allocatable :: optional_dummy(:)
        integer, allocatable :: formals(:), values(:), positions(:)
        type(string_t), allocatable :: names(:)
        type(declaration_binding_t) :: binding
        character(len=:), allocatable :: error_msg, keyword
        integer :: n, n_actual, j, a, d, position, target
        logical :: seen_keyword, permit_optional

        score = -1; rank = 0; elemental = .false.
        if (.not. arena%has_node_at(procedure_index)) return
        n_actual = 0; permit_optional = .false.
        if (present(allow_optional)) permit_optional = allow_optional
        if (allocated(actuals)) n_actual = size(actuals)
        select type (proc => arena%entries(procedure_index)%node)
        type is (function_def_node)
            elemental = is_elemental_prefix(proc%prefix_keywords)
            if (.not. allocated(proc%param_indices)) then
                if (n_actual == 0) score = 1
                return
            end if
            n = size(proc%param_indices)
            if (n_actual > n) return
            if (.not. permit_optional .and. n_actual /= n) return
            formals = proc%param_indices
        class default
            return
        end select
        allocate(names(n), values(n), positions(n), optional_dummy(n))
        optional_dummy = .false.
        positions = 0; values = 0
        do j = 1, n
            if (.not. arena%has_node_at(formals(j))) return
            select type (formal => arena%entries(formals(j))%node)
            type is (parameter_declaration_node)
                if (.not. allocated(formal%name)) return
                names(j)%s = to_lower(formal%name)
            class default
                return
            end select
            call resolve_name_in_scope(arena, procedure_index, names(j)%s, binding, error_msg)
            if (.not. binding%found) return
            formals(j) = binding%declaration_node_index
            if (.not. arena%has_node_at(formals(j))) return
            select type (dummy => arena%entries(formals(j))%node)
            type is (declaration_node)
                optional_dummy(j) = dummy%is_optional
            type is (parameter_declaration_node)
                optional_dummy(j) = dummy%is_optional
            class default
                return
            end select
            ! Defined operator operands are never OPTIONAL. Named generic
            ! calls may omit only source-declared OPTIONAL formals.
            if (optional_dummy(j) .and. .not. permit_optional) return
            call resolve_node_metadata(arena, formals(j), visiting)
        end do
        seen_keyword = .false.
        do j = 1, n_actual
            a = actuals(j); keyword = ''
            if (.not. arena%has_node_at(a)) return
            select type (actual => arena%entries(a)%node)
            type is (assignment_node)
                if (.not. actual%is_keyword_argument) return
                target = actual%target_index
                if (.not. arena%has_node_at(target)) return
                select type (name => arena%entries(target)%node)
                type is (identifier_node)
                    if (.not. allocated(name%name)) return
                    keyword = to_lower(name%name)
                class default
                    return
                end select
                a = actual%value_index; seen_keyword = .true.
            class default
                if (seen_keyword) return
            end select
            position = j
            if (len_trim(keyword) > 0) then
                do position = 1, n
                    if (names(position)%s == keyword) exit
                end do
            end if
            if (position > n) return
            if (positions(position) /= 0) return
            positions(position) = j; values(position) = a
        end do
        score = 1
        do j = 1, n
            a = values(j); d = formals(j)
            if (a == 0) then
                if (optional_dummy(j)) cycle
                score = -1; return
            end if
            if (.not. arena%has_node_at(a)) then
                score = -1; return
            end if
            call resolve_node_metadata(arena, a, visiting)
            associate(actual => arena%entries(a)%node, dummy => arena%entries(d)%node)
                if (.not. actual%resolved_type_found .or. .not. dummy%resolved_type_found) then
                    score = -1; return
                end if
                if (actual%resolved_type_kind /= dummy%resolved_type_kind .or. &
                    actual%resolved_kind_value /= dummy%resolved_kind_value .or. &
                    actual%resolved_derived_type_name /= dummy%resolved_derived_type_name) then
                    score = -1; return
                end if
                if (actual%resolved_rank /= dummy%resolved_rank) then
                    if (elemental .and. dummy%resolved_rank == 0 .and. actual%resolved_rank > 0) then
                        score = 0
                    else
                        score = -1; return
                    end if
                end if
                rank = max(rank, actual%resolved_rank)
            end associate
        end do
    end subroutine match_named_generic_candidate

    subroutine resolve_intrinsic_call(arena, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        type(call_or_subscript_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        character(len=:), allocatable :: name
        integer :: kind_value, result_type, result_rank, i, argument_index

        name = to_lower(trim(node%name))
        result_type = inferred_base_kind(node%inferred_type, result_rank)
        result_type = normalize_type_kind(result_type)

        ! These elemental intrinsics preserve the conforming actual shape.
        ! Reductions, transformations and inquiries keep their separate rules.
        select case (name)
        case ("iand", "ior", "ieor", "not", "btest", "leadz", "trailz", "maskl", "maskr", "shiftr", "lge", "lgt", "lle", "llt", "acosd", "asind", "sind", "cosd", "rrspacing", "asin", "atan", "atan2", "acos", "dprod", "tand", "aint", "anint", "asinh", "acosh", "fraction", "exponent", "set_exponent", "iachar", "real", "int", "nint", "floor", "ceiling", "dble", "merge", "logical", "cmplx", "aimag", "abs", &
              "exp", "log", "log10", "log_gamma", "dim", "sign", "spacing", "nearest", "isnan", "erfc_scaled", "erf", "bessel_j0", "bessel_j1", "bessel_jn", "bessel_y0", "bessel_y1", "bessel_yn", "sqrt", "erfc", "sinh", "cosh", "tanh", "min", "max", "char", "achar", "index", "scan", "verify", "len_trim", "adjustl", "adjustr")
            result_rank = 0
            if (allocated(node%arg_indices)) then
                do i = 1, size(node%arg_indices)
                    argument_index = node%arg_indices(i)
                    if (.not. arena%has_node_at(argument_index)) cycle
                    call resolve_node_metadata(arena, argument_index, visiting)
                    result_rank = max(result_rank, &
                        arena%entries(argument_index)%node%resolved_rank)
                end do
            end if
        end select

        select case (name)
        case ("iand", "ior", "ieor", "not", "bit_size")
            call first_intrinsic_argument_metadata(arena,node,visiting,result_type,kind_value)
            if(name=="bit_size")result_rank=0
            if(kind_value>0)call set_intrinsic_metadata(node,TINT,kind_value,result_rank)
        case ("maskl", "maskr")
            kind_value = intrinsic_kind_argument(arena,node,name)
            if(kind_value<=0)kind_value=4
            call set_intrinsic_metadata(node,TINT,kind_value,result_rank)
        case ("shiftr")
            call bit_i_argument_kind(arena,node,visiting,kind_value)
            if(kind_value>0)call set_intrinsic_metadata(node,TINT,kind_value,result_rank)
        case ("leadz", "trailz")
            call set_intrinsic_metadata(node,TINT,4,result_rank)
        case ("btest")
            call set_intrinsic_metadata(node,TLOGICAL,4,result_rank)
        case ("lge", "lgt", "lle", "llt")
            call set_intrinsic_metadata(node,TLOGICAL,4,result_rank)
        case ("associated")
            call set_intrinsic_metadata(node,TLOGICAL,4,0)
        case ("index", "scan", "verify", "len_trim", "iachar")
            kind_value = intrinsic_kind_argument(arena, node, name)
            if (kind_value <= 0) kind_value = 4
            call set_intrinsic_metadata(node, TINT, kind_value, result_rank)
        case ("transpose")
            call resolve_transpose_metadata(arena, node, visiting)
        case ("cshift", "eoshift")
            call resolve_cshift_metadata(arena, node, visiting)
        case ("lbound", "ubound")
            call resolve_bounds_inquiry_metadata(arena,node,visiting)
        case ("shape")
            kind_value = intrinsic_kind_argument(arena, node, name)
            if (kind_value <= 0) kind_value = 4
            call set_intrinsic_metadata(node, TINT, kind_value, 1)
        case ("exponent")
            call set_intrinsic_metadata(node, TINT, 4, result_rank)
        case ("fraction", "set_exponent")
            call decomposition_x_metadata(arena,node,visiting,kind_value)
            if(kind_value>0)call set_intrinsic_metadata(node,TREAL,kind_value,result_rank)
        case ("aint", "anint")
            call resolve_real_round_metadata(arena,node,visiting)
        case ("dprod")
            call set_intrinsic_metadata(node,TREAL,8,result_rank)
        case ("acosd", "asind", "sind", "cosd", "rrspacing", "asin", "atan", "atan2", "acos", "tand", "asinh", "acosh")
            call first_intrinsic_argument_metadata(arena,node,visiting,result_type,kind_value)
            if(kind_value>0)call set_intrinsic_metadata(node,TREAL,kind_value,result_rank)
        case ("erf", "bessel_j0", "bessel_j1", "bessel_jn", "bessel_y0", "bessel_y1", "bessel_yn")
            call erf_bessel_x_metadata(arena,node,visiting,name,result_type,kind_value)
            if (result_type > 0 .and. kind_value > 0) &
                call set_intrinsic_metadata(node,result_type,kind_value,result_rank)
        case ("erfc_scaled")
            call first_intrinsic_argument_metadata(arena, node, visiting, &
                result_type, kind_value)
            if (result_type > 0 .and. kind_value > 0) &
                call set_intrinsic_metadata(node, result_type, kind_value, result_rank)
        case ("isnan")
            call set_intrinsic_metadata(node, TLOGICAL, 4, result_rank)
        case ("repeat", "new_line")
            call set_intrinsic_metadata(node, TCHAR, 1, 0)
        case ("adjustl", "adjustr")
            call set_intrinsic_metadata(node, TCHAR, 1, result_rank)
        case ("char", "achar")
            kind_value = intrinsic_kind_argument(arena, node, name)
            if (kind_value <= 0) kind_value = 1
            call set_intrinsic_metadata(node, TCHAR, kind_value, result_rank)
        case ("real", "int", "nint", "floor", "ceiling", "logical", "cmplx")
            kind_value = intrinsic_kind_argument(arena, node, name)
            if (kind_value <= 0 .and. name == "real") then
                call real_result_kind_from_argument(arena, node, visiting, &
                    kind_value)
            end if
            if (kind_value <= 0) kind_value = 4
            select case (name)
            case ("real")
                result_type = TREAL
            case ("int", "nint", "floor", "ceiling")
                result_type = TINT
            case ("logical")
                result_type = TLOGICAL
            case ("cmplx")
                result_type = TCOMPLEX
            end select
            call set_intrinsic_metadata(node, result_type, kind_value, result_rank)
        case ("spacing", "nearest")
            call resolve_spacing_nearest_metadata(arena,node,visiting,result_rank)
        case ("exp", "log", "log10", "log_gamma", "dim", "sign", "sqrt", "erfc", "sinh", "cosh", "tanh", "min", "max")
            call first_intrinsic_argument_metadata(arena, node, visiting, &
                result_type, kind_value)
            if (result_type > 0 .and. kind_value > 0) &
                call set_intrinsic_metadata(node, result_type, kind_value, result_rank)
        case ("dble")
            call set_intrinsic_metadata(node, TREAL, 8, result_rank)
        case ("merge")
            call resolve_merge_metadata(arena, node, visiting, result_rank)
        case ("norm2", "sum", "product", "minval", "maxval", "all", "any", "count", "parity", "minloc", "maxloc", "findloc")
            call resolve_reduction_metadata(arena, node, visiting)
        case ("epsilon", "tiny", "huge")
            call first_intrinsic_argument_metadata(arena, node, visiting, &
                result_type, kind_value)
            if (result_type > 0 .and. kind_value > 0) &
                call set_intrinsic_metadata(node, result_type, kind_value, 0)
        case ("kind", "selected_int_kind", "selected_real_kind", "digits", "radix", "minexponent", "maxexponent")
            call set_intrinsic_metadata(node, TINT, 4, 0)
        case ("aimag", "abs")
            call resolve_unary_same_kind_intrinsic(arena, node, visiting, name, &
                result_rank)
        case default
            if (.not. allocated(node%arg_indices)) return
            if (size(node%arg_indices) <= 0) return
            call resolve_node_metadata(arena, node%arg_indices(1), visiting)
            if (.not. arena%has_node_at(node%arg_indices(1))) return
            kind_value = &
                arena%entries(node%arg_indices(1))%node%resolved_kind_value
            if (result_type > 0 .and. kind_value > 0) then
                call set_intrinsic_metadata(node, result_type, kind_value, &
                    result_rank)
            end if
        end select
    end subroutine resolve_intrinsic_call

    subroutine resolve_bounds_inquiry_metadata(arena,node,visiting)
        type(ast_arena_t),intent(inout)::arena
        type(call_or_subscript_node),intent(inout)::node
        logical,intent(inout)::visiting(:)
        integer::i,arg,kind_value,rank,source,positional
        character(:),allocatable::keyword
        kind_value=4;rank=1;source=0;positional=0
        if(.not.allocated(node%arg_indices))return
        do i=1,size(node%arg_indices)
            arg=node%arg_indices(i);keyword=''
            if(.not.arena%has_node_at(arg))return
            select type(actual=>arena%entries(arg)%node)
            type is(assignment_node)
                if(.not.actual%is_keyword_argument)return
                if(.not.arena%has_node_at(actual%target_index))return
                select type(key=>arena%entries(actual%target_index)%node)
                type is(identifier_node)
                    keyword=to_lower(key%name)
                end select
                arg=actual%value_index
            class default
                positional=positional+1
                select case(positional)
                case(1);keyword='array'
                case(2);keyword='dim'
                case(3);keyword='kind'
                end select
            end select
            if(.not.arena%has_node_at(arg))return
            call resolve_node_metadata(arena,arg,visiting)
            select case(keyword)
            case('array');source=arg
            case('dim');rank=0
            case('kind');call evaluate_integer_constant(arena,arg,kind_value,visiting)
            end select
        end do
        if(.not.arena%has_node_at(source).or.kind_value<=0)return
        call set_intrinsic_metadata(node,TINT,kind_value,rank)
    end subroutine
    recursive subroutine resolve_transpose_metadata(arena, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        type(call_or_subscript_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        integer :: i, arg, source
        source = 0
        if (.not. allocated(node%arg_indices)) return
        do i = 1, size(node%arg_indices)
            arg = node%arg_indices(i)
            if (.not. arena%has_node_at(arg)) return
            select type (actual => arena%entries(arg)%node)
            type is (assignment_node)
                if (.not. actual%is_keyword_argument) return
                if (.not. arena%has_node_at(actual%target_index)) return
                select type (key => arena%entries(actual%target_index)%node)
                type is (identifier_node)
                    if (to_lower(key%name) == 'matrix') source = actual%value_index
                end select
            class default
                if (i == 1) source = arg
            end select
        end do
        if (.not. arena%has_node_at(source)) return
        call resolve_node_metadata(arena, source, visiting)
        call copy_metadata_from_index(arena, source, node)
    end subroutine resolve_transpose_metadata

    recursive subroutine resolve_cshift_metadata(arena, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        type(call_or_subscript_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        integer :: i, arg, source
        source = 0
        if (.not. allocated(node%arg_indices)) return
        do i = 1, size(node%arg_indices)
            arg = node%arg_indices(i)
            if (.not. arena%has_node_at(arg)) return
            select type (actual => arena%entries(arg)%node)
            type is (assignment_node)
                if (.not. actual%is_keyword_argument) return
                if (.not. arena%has_node_at(actual%target_index)) return
                select type (key => arena%entries(actual%target_index)%node)
                type is (identifier_node)
                    if (to_lower(key%name) == 'array') source = actual%value_index
                end select
            class default
                if (i == 1) source = arg
            end select
        end do
        if (.not. arena%has_node_at(source)) return
        call resolve_node_metadata(arena, source, visiting)
        call copy_metadata_from_index(arena, source, node)
    end subroutine resolve_cshift_metadata

    subroutine resolve_reduction_metadata(arena, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        type(call_or_subscript_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        integer :: i, idx, value_index, array_index, positional, rank, kind_value, result_type, value_offset
        logical :: has_dim, keyword, logical_reduction, location_reduction
        character(:), allocatable :: argument_name

        if (.not. allocated(node%arg_indices)) return
        array_index = 0
        kind_value = 4
        logical_reduction = any(to_lower(node%name) == [character(6)::'all','any','count','parity'])
        location_reduction = any(to_lower(node%name) == [character(7)::'minloc','maxloc','findloc'])
        value_offset = merge(1, 0, to_lower(node%name) == "findloc")
        positional = 0
        has_dim = .false.
        do i = 1, size(node%arg_indices)
            idx = node%arg_indices(i)
            if (.not. arena%has_node_at(idx)) cycle
            value_index = idx
            keyword = .false.
            argument_name = ''
            select type (arg => arena%entries(idx)%node)
            type is (assignment_node)
                if (arg%is_keyword_argument) then
                    keyword = .true.
                    value_index = arg%value_index
                    if (arena%has_node_at(arg%target_index)) then
                        select type (target => arena%entries(arg%target_index)%node)
                        type is (identifier_node)
                            argument_name = to_lower(target%name)
                        end select
                    end if
                end if
            end select
            call resolve_node_metadata(arena, value_index, visiting)
            if (.not. arena%has_node_at(value_index)) cycle
            if (keyword) then
                if (argument_name == 'array'.or.(logical_reduction.and.argument_name == 'mask').or. &
                    (to_lower(node%name)=='norm2'.and.argument_name=='x')) &
                    array_index = value_index
                if ((logical_reduction.or.location_reduction).and.argument_name == 'kind') &
                    call evaluate_integer_constant(arena,value_index,kind_value,visiting)
                if (argument_name == 'dim') has_dim = .true.
            else
                positional = positional + 1
                if (positional == 1) array_index = value_index
                if (logical_reduction.and.positional == 3) &
                    call evaluate_integer_constant(arena,value_index,kind_value,visiting)
                if (location_reduction.and. &
                    ((has_dim.and.positional==4+value_offset).or.(.not.has_dim.and.positional==3+value_offset))) &
                    call evaluate_integer_constant(arena,value_index,kind_value,visiting)
                if (positional == 2+value_offset) then
                    has_dim = arena%entries(value_index)%node%resolved_type_kind == TINT
                end if
            end if
        end do
        if (.not. arena%has_node_at(array_index)) return
        if (.not. arena%entries(array_index)%node%resolved_type_found) return
        rank = 0
        if (location_reduction) rank = 1
        if (has_dim) rank = max(0, arena%entries(array_index)%node%resolved_rank - 1)
        result_type = arena%entries(array_index)%node%resolved_type_kind
        if (.not.logical_reduction.and..not.location_reduction) kind_value = arena%entries(array_index)%node%resolved_kind_value
        if (to_lower(node%name) == 'count'.or.location_reduction) result_type = TINT
        call set_intrinsic_metadata(node, result_type, kind_value, rank)
    end subroutine resolve_reduction_metadata

    subroutine resolve_spacing_nearest_metadata(arena,node,visiting,result_rank)
        type(ast_arena_t),intent(inout)::arena
        type(call_or_subscript_node),intent(inout)::node
        logical,intent(inout)::visiting(:)
        integer,intent(in)::result_rank
        integer::j,arg,source
        source=0
        if(.not.allocated(node%arg_indices)) return
        do j=1,size(node%arg_indices)
            arg=node%arg_indices(j)
            if(.not.arena%has_node_at(arg)) return
            select type(actual=>arena%entries(arg)%node)
            type is(assignment_node)
                if(.not.actual%is_keyword_argument) return
                if(.not.arena%has_node_at(actual%target_index)) return
                select type(label=>arena%entries(actual%target_index)%node)
                type is(identifier_node)
                    if(to_lower(label%name)=='x') source=actual%value_index
                end select
            class default
                if(j==1) source=arg
            end select
        end do
        if(.not.arena%has_node_at(source)) return
        call resolve_node_metadata(arena,source,visiting)
        call set_intrinsic_metadata(node,arena%entries(source)%node%resolved_type_kind, &
            arena%entries(source)%node%resolved_kind_value,result_rank)
    end subroutine resolve_spacing_nearest_metadata

    subroutine resolve_merge_metadata(arena,node,visiting,result_rank)
        type(ast_arena_t),intent(inout)::arena
        type(call_or_subscript_node),intent(inout)::node
        logical,intent(inout)::visiting(:)
        integer,intent(in)::result_rank
        integer::j,arg,source
        source=0
        if(.not.allocated(node%arg_indices)) return
        do j=1,size(node%arg_indices)
            arg=node%arg_indices(j)
            if(.not.arena%has_node_at(arg)) return
            select type(actual=>arena%entries(arg)%node)
            type is(assignment_node)
                if(.not.actual%is_keyword_argument) return
                if(.not.arena%has_node_at(actual%target_index)) return
                select type(label=>arena%entries(actual%target_index)%node)
                type is(identifier_node)
                    if(to_lower(label%name)=='tsource') source=actual%value_index
                end select
            class default
                if(j==1) source=arg
            end select
        end do
        if(.not.arena%has_node_at(source)) return
        call resolve_node_metadata(arena,source,visiting)
        call set_intrinsic_metadata(node,arena%entries(source)%node%resolved_type_kind, &
            arena%entries(source)%node%resolved_kind_value,result_rank)
    end subroutine resolve_merge_metadata

    subroutine resolve_unary_same_kind_intrinsic(arena, node, visiting, name, &
            result_rank)
        type(ast_arena_t), intent(inout) :: arena
        type(call_or_subscript_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        character(len=*), intent(in) :: name
        integer, intent(in) :: result_rank
        integer :: argument_type, argument_kind, result_type, argument_rank

        call first_intrinsic_argument_metadata(arena, node, visiting, &
            argument_type, argument_kind)
        if (argument_kind <= 0) return
        argument_rank = result_rank
        if (allocated(node%arg_indices)) then
            if (size(node%arg_indices) > 0) then
                if (arena%has_node_at(node%arg_indices(1))) &
                    argument_rank = arena%entries(node%arg_indices(1))%node%resolved_rank
            end if
        end if

        select case (name)
        case ("aimag")
            if (argument_type /= TCOMPLEX) return
            call set_intrinsic_metadata(node, TREAL, argument_kind, argument_rank)
        case ("abs")
            result_type = argument_type
            if (argument_type == TCOMPLEX) result_type = TREAL
            select case (result_type)
            case (TINT, TREAL)
                call set_intrinsic_metadata(node, result_type, argument_kind, &
                    argument_rank)
            end select
        end select
    end subroutine resolve_unary_same_kind_intrinsic

    subroutine resolve_component_access(arena, node_index, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: node_index
        type(component_access_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        type(declaration_binding_t) :: binding
        character(len=:), allocatable :: error_msg
        character(len=:), allocatable :: derived_name
        integer :: derived_index

        if (node%base_expr_index <= 0) return
        if (.not. allocated(node%component_name)) return
        call resolve_node_metadata(arena, node%base_expr_index, visiting)
        if (.not. arena%has_node_at(node%base_expr_index)) return
        ! Intrinsic CHARACTER type-parameter inquiry, not a component value.
        if (to_lower(node%component_name) == 'len') then
            if (arena%entries(node%base_expr_index)%node%resolved_type_kind == TCHAR) then
                call set_intrinsic_metadata(node, TINT, 4, 0)
                return
            end if
        end if
        derived_name = trim(arena%entries(node%base_expr_index)%node% &
            resolved_derived_type_name)
        if (len_trim(derived_name) == 0) return

        call resolve_name_at_node(arena, node_index, derived_name, binding, error_msg)
        if (.not. binding%found) return
        derived_index = binding%declaration_node_index
        call resolve_component_in_type(arena, derived_index, node%component_name, &
            node, visiting)
    end subroutine resolve_component_access

    recursive subroutine resolve_component_in_type(arena, derived_index, &
            component_name, target, visiting)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: derived_index
        character(len=*), intent(in) :: component_name
        class(ast_node), intent(inout) :: target
        logical, intent(inout) :: visiting(:)
        integer :: i, component_index

        if (.not. arena%has_node_at(derived_index)) return
        select type (derived => arena%entries(derived_index)%node)
            type is (derived_type_node)
            if (.not. allocated(derived%component_indices)) return
            do i = 1, size(derived%component_indices)
                component_index = derived%component_indices(i)
                if (.not. declaration_has_name(arena, component_index, &
                    component_name)) cycle
                call resolve_node_metadata(arena, component_index, visiting)
                call copy_metadata_from_index(arena, component_index, target)
                return
            end do
        end select
    end subroutine resolve_component_in_type

    subroutine resolve_function_result(arena, node_index, node, visiting)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: node_index
        type(function_def_node), intent(inout) :: node
        logical, intent(inout) :: visiting(:)
        character(len=:), allocatable :: result_name
        integer :: i, body_index

        result_name = ""
        if (allocated(node%result_variable)) then
            result_name = trim(node%result_variable)
        else if (allocated(node%name)) then
            result_name = trim(node%name)
        end if
        ! A result declaration carries the rank and exact declared type. A
        ! provisional return_type may still contain implicit REAL here.
        if (len_trim(result_name) > 0 .and. allocated(node%body_indices)) then
            do i = 1, size(node%body_indices)
                body_index = node%body_indices(i)
                if (.not. declaration_has_name(arena, body_index, result_name)) cycle
                call resolve_node_metadata(arena, body_index, visiting)
                call copy_metadata_from_index(arena, body_index, node)
                if (node%resolved_type_found) return
            end do
        end if

        if (allocated(node%return_type)) then
            if (len_trim(node%return_type) > 0) then
                call resolve_type_spec(arena, node_index, node%return_type, &
                    .false., 0, 0, node)
                if (node%resolved_type_found) return
            end if
        end if

    end subroutine resolve_function_result

    subroutine resolve_type_spec(arena, node_index, type_name, has_kind, &
            explicit_kind, rank, node)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: node_index
        character(len=*), intent(in) :: type_name
        logical, intent(in) :: has_kind
        integer, intent(in) :: explicit_kind
        integer, intent(in) :: rank
        class(ast_node), intent(inout) :: node
        character(len=:), allocatable :: lowered, selector, derived_name
        integer :: type_kind, kind_value
        logical :: selector_found

        lowered = compact_lower(type_name)
        type_kind = type_kind_from_spec(lowered)
        if (type_kind == TDERIVED) then
            derived_name = derived_name_from_spec(lowered)
            call set_derived_metadata(node, derived_name, rank)
            return
        end if
        if (type_kind <= 0) return

        kind_value = 0
        if (has_kind .and. explicit_kind > 0) then
            kind_value = explicit_kind
        else
            call selector_from_type_spec(lowered, type_kind, selector, &
                selector_found)
            if (selector_found) then
                kind_value = resolve_kind_selector(arena, node_index, selector)
            else
                kind_value = default_kind_for_type(type_kind)
            end if
        end if
        call set_intrinsic_metadata(node, type_kind, kind_value, rank)
    end subroutine resolve_type_spec

    subroutine resolve_from_inferred_type(node)
        class(ast_node), intent(inout) :: node
        integer :: rank, raw_type_kind, type_kind, kind_value

        raw_type_kind = inferred_base_kind(node%inferred_type, rank)
        type_kind = normalize_type_kind(raw_type_kind)
        if (type_kind <= 0) return
        if (raw_type_kind == TDOUBLE) then
            kind_value = 8
        else
            kind_value = default_kind_for_type(type_kind)
        end if
        call set_intrinsic_metadata(node, type_kind, kind_value, rank)
    end subroutine resolve_from_inferred_type

    subroutine set_intrinsic_metadata(node, type_kind, kind_value, rank)
        class(ast_node), intent(inout) :: node
        integer, intent(in) :: type_kind, kind_value, rank

        node%resolved_type_kind = normalize_type_kind(type_kind)
        node%resolved_kind_value = kind_value
        node%resolved_rank = rank
        node%resolved_storage_bits = storage_bits_for_type( &
            node%resolved_type_kind, kind_value)
        node%resolved_derived_type_name = ""
        node%resolved_type_found = node%resolved_type_kind > 0
        if (node%resolved_type_kind /= TDERIVED) then
            node%resolved_type_found = node%resolved_type_found .and. &
                kind_value > 0
        end if
    end subroutine set_intrinsic_metadata

    subroutine set_derived_metadata(node, derived_name, rank)
        class(ast_node), intent(inout) :: node
        character(len=*), intent(in) :: derived_name
        integer, intent(in) :: rank

        node%resolved_type_kind = TDERIVED
        node%resolved_kind_value = 0
        node%resolved_storage_bits = 0
        node%resolved_rank = rank
        node%resolved_derived_type_name = trim(derived_name)
        node%resolved_type_found = len_trim(derived_name) > 0
    end subroutine set_derived_metadata

    subroutine copy_metadata_from_index(arena, source_index, target)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: source_index
        class(ast_node), intent(inout) :: target

        if (.not. arena%has_node_at(source_index)) return
        associate (source => arena%entries(source_index)%node)
            target%resolved_type_found = source%resolved_type_found
            target%resolved_type_kind = source%resolved_type_kind
            target%resolved_kind_value = source%resolved_kind_value
            target%resolved_storage_bits = source%resolved_storage_bits
            target%resolved_rank = source%resolved_rank
            target%resolved_derived_type_name = &
                source%resolved_derived_type_name
        end associate
    end subroutine copy_metadata_from_index

    subroutine get_metadata(arena, node_index, type_kind, kind_value, rank)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: node_index
        integer, intent(out) :: type_kind, kind_value
        integer, intent(inout) :: rank

        type_kind = 0
        kind_value = 0
        if (.not. arena%has_node_at(node_index)) return
        type_kind = arena%entries(node_index)%node%resolved_type_kind
        kind_value = arena%entries(node_index)%node%resolved_kind_value
        rank = max(rank, arena%entries(node_index)%node%resolved_rank)
    end subroutine get_metadata

    integer function inferred_base_kind(typ, rank) result(type_kind)
        type(mono_type_t), intent(in) :: typ
        integer, intent(out) :: rank
        type(mono_type_t) :: current

        rank = 0
        current = typ
        do while (current%kind == TARRAY)
            rank = rank + 1
            if (current%get_args_count() <= 0) then
                type_kind = 0
                return
            end if
            current = current%get_arg(1)
        end do
        type_kind = current%kind
    end function inferred_base_kind

    integer pure function normalize_type_kind(type_kind) result(normalized)
        integer, intent(in) :: type_kind

        if (type_kind == TDOUBLE) then
            normalized = TREAL
        else
            normalized = type_kind
        end if
    end function normalize_type_kind

    integer pure function default_kind_for_type(type_kind) result(kind_value)
        integer, intent(in) :: type_kind

        select case (normalize_type_kind(type_kind))
        case (TCHAR)
            kind_value = 1
        case (TINT, TLOGICAL, TCOMPLEX)
            kind_value = 4
        case (TREAL)
            ! Lazy dialect: kind-less real is real64. Standard Fortran keeps
            ! the language default real kind; callers that need a standardized
            ! Lazy signature promote its abstract TREAL below.
            if (get_standardizer_input_mode() == INPUT_MODE_LAZY) then
                kind_value = 8
            else
                kind_value = 4
            end if
        case default
            kind_value = 0
        end select
    end function default_kind_for_type

    integer pure function storage_bits_for_type(type_kind, kind_value) result(bits)
        integer, intent(in) :: type_kind, kind_value

        bits = 0
        if (kind_value <= 0) return
        select case (normalize_type_kind(type_kind))
        case (TINT, TLOGICAL, TCHAR)
            bits = 8 * kind_value
        case (TREAL)
            select case (kind_value)
            case (1, 2, 4, 8)
                bits = 8 * kind_value
            case (10, 16)
                bits = 128
            end select
        case (TCOMPLEX)
            select case (kind_value)
            case (1, 2, 4, 8)
                bits = 16 * kind_value
            case (10, 16)
                bits = 256
            end select
        end select
    end function storage_bits_for_type

    integer pure function type_kind_from_spec(type_spec) result(type_kind)
        character(len=*), intent(in) :: type_spec

        type_kind = 0
        if (index(type_spec, "doubleprecision") == 1) then
            type_kind = TREAL
        else if (index(type_spec, "integer") == 1) then
            type_kind = TINT
        else if (index(type_spec, "real") == 1) then
            type_kind = TREAL
        else if (index(type_spec, "logical") == 1) then
            type_kind = TLOGICAL
        else if (index(type_spec, "complex") == 1) then
            type_kind = TCOMPLEX
        else if (index(type_spec, "character") == 1) then
            type_kind = TCHAR
        else if (index(type_spec, "type(") == 1 .or. &
                index(type_spec, "class(") == 1) then
            type_kind = TDERIVED
        end if
    end function type_kind_from_spec

    subroutine selector_from_type_spec(type_spec, type_kind, selector, found)
        character(len=*), intent(in) :: type_spec
        integer, intent(in) :: type_kind
        character(len=:), allocatable, intent(out) :: selector
        logical, intent(out) :: found
        integer :: open_pos, close_pos, kind_pos, comma_pos
        character(len=:), allocatable :: contents

        selector = ""
        found = .false.
        if (index(type_spec, "doubleprecision") == 1) then
            selector = "8"
            found = .true.
            return
        end if

        open_pos = index(type_spec, "(")
        close_pos = index(type_spec, ")", back=.true.)
        if (open_pos <= 0) return
        if (close_pos <= open_pos) return
        contents = type_spec(open_pos + 1:close_pos - 1)

        if (type_kind == TCHAR) then
            kind_pos = index(contents, "kind=")
            if (kind_pos <= 0) return
            contents = contents(kind_pos + len("kind="):)
        else
            kind_pos = index(contents, "kind=")
            if (kind_pos > 0) contents = contents(kind_pos + len("kind="):)
        end if
        comma_pos = index(contents, ",")
        if (comma_pos > 0) contents = contents(:comma_pos - 1)
        selector = trim(contents)
        found = len_trim(selector) > 0
    end subroutine selector_from_type_spec

    function derived_name_from_spec(type_spec) result(name)
        character(len=*), intent(in) :: type_spec
        character(len=:), allocatable :: name
        integer :: open_pos, close_pos, comma_pos

        name = ""
        open_pos = index(type_spec, "(")
        close_pos = index(type_spec, ")", back=.true.)
        if (open_pos <= 0) return
        if (close_pos <= open_pos) return
        name = type_spec(open_pos + 1:close_pos - 1)
        comma_pos = index(name, ",")
        if (comma_pos > 0) name = name(:comma_pos - 1)
        name = trim(name)
    end function derived_name_from_spec

    subroutine literal_selector(raw_value, selector, found)
        character(len=*), intent(in) :: raw_value
        character(len=:), allocatable, intent(out) :: selector
        logical, intent(out) :: found
        character(len=:), allocatable :: lowered
        integer :: underscore_pos

        selector = ""
        found = .false.
        lowered = compact_lower(raw_value)
        underscore_pos = index(lowered, "_", back=.true.)
        if (underscore_pos <= 0) return
        if (underscore_pos >= len(lowered)) return
        selector = lowered(underscore_pos + 1:)
        found = len_trim(selector) > 0
    end subroutine literal_selector

    logical function has_double_exponent(raw_value) result(has_double)
        character(len=*), intent(in) :: raw_value
        character(len=:), allocatable :: lowered
        integer :: underscore_pos

        lowered = compact_lower(raw_value)
        underscore_pos = index(lowered, "_", back=.true.)
        if (underscore_pos > 0) lowered = lowered(:underscore_pos - 1)
        has_double = index(lowered, "d") > 0
    end function has_double_exponent

    integer function resolve_kind_expression(arena, expr_index) result(kind_value)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: expr_index
        logical, allocatable :: visiting(:)
        kind_value = 0
        if (.not. arena%has_node_at(expr_index)) return
        allocate (visiting(arena%size), source=.false.)
        call evaluate_integer_constant(arena, expr_index, kind_value, visiting)
    end function resolve_kind_expression

    integer function resolve_kind_selector(arena, reference_index, selector) &
            result(kind_value)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: reference_index
        character(len=*), intent(in) :: selector
        character(len=:), allocatable :: lowered
        integer :: ios
        logical, allocatable :: visiting(:)

        kind_value = 0
        lowered = compact_lower(selector)

        read (lowered, *, iostat=ios) kind_value
        if (ios == 0) return
        kind_value = 0

        ! A constant declared in scope outranks the conventional spelling so an
        ! explicitly shadowed selector keeps its declared value.
        if (arena%size > 0) then
            allocate (visiting(arena%size), source=.false.)
            call resolve_named_integer_constant(arena, reference_index, lowered, &
                kind_value, visiting)
            if (kind_value > 0) return
        end if

        if (resolve_intrinsic_module_kind(arena, reference_index, lowered, &
            kind_value)) return

        kind_value = conventional_kind_selector(lowered)
    end function resolve_kind_selector

    ! Kind names carried by the iso_fortran_env rename idiom, which leaves no
    ! declaration in the arena to resolve against.
    integer pure function conventional_kind_selector(selector) result(kind_value)
        character(len=*), intent(in) :: selector

        select case (selector)
        case ("int8")
            kind_value = 1
        case ("int16")
            kind_value = 2
        case ("int32", "real32", "sp")
            kind_value = 4
        case ("int64", "real64", "double", "doubleprecision", "dp")
            kind_value = 8
        case ("real128", "qp")
            kind_value = 16
        case default
            kind_value = 0
        end select
    end function conventional_kind_selector

    logical function resolve_intrinsic_module_kind(arena, reference_index, selector, &
            kind_value) result(found)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: reference_index
        character(len=*), intent(in) :: selector
        integer, intent(out) :: kind_value
        integer :: current, child, i
        logical :: imported
        character(len=:), allocatable :: canonical_selector, remote_selector
        character(len=:), allocatable :: module_name

        found = .false.
        kind_value = 0
        current = reference_index
        do while (current > 0)
            if (.not. arena%has_node_at(current)) return
            if (allocated(arena%entries(current)%child_indices)) then
                do i = 1, arena%entries(current)%child_count
                    child = arena%entries(current)%child_indices(i)
                    if (.not. arena%has_node_at(child)) cycle
                    select type (use_node => arena%entries(child)%node)
                    type is (use_statement_node)
                        if (.not. allocated(use_node%module_name)) cycle
                        module_name = compact_lower(use_node%module_name)
                        if (module_name /= 'iso_c_binding' .and. &
                            module_name /= 'iso_fortran_env') cycle
                        canonical_selector = compact_lower(selector)
                        imported = .false.
                        ! Resolve a local rename before its ONLY-list entry,
                        ! which may contain the local rather than remote name.
                        if (allocated(use_node%rename_list)) then
                            imported = use_rename_contains(use_node%rename_list, &
                                selector, remote_selector)
                            if (imported) canonical_selector = &
                                compact_lower(remote_selector)
                        end if
                        if (.not. imported) then
                            if (.not. use_node%has_only) then
                                imported = .true.
                            else if (allocated(use_node%only_list)) then
                                imported = use_list_contains(use_node%only_list, &
                                    selector)
                            end if
                        end if
                        if (.not. imported) cycle
                        kind_value = intrinsic_module_kind_value(module_name, &
                            canonical_selector)
                        if (kind_value > 0) then
                            found = .true.
                            return
                        end if
                    end select
                end do
            end if
            current = arena%entries(current)%parent_index
        end do
    end function resolve_intrinsic_module_kind

    integer pure function intrinsic_module_kind_value(module_name, selector) &
            result(kind_value)
        character(len=*), intent(in) :: module_name, selector

        kind_value = 0
        if (module_name == 'iso_fortran_env') then
            select case (selector)
            case ('int8')
                kind_value = 1
            case ('int16')
                kind_value = 2
            case ('int32', 'real32')
                kind_value = 4
            case ('int64', 'real64')
                kind_value = 8
            case ('real128')
                kind_value = 16
            end select
            return
        end if
        select case (selector)
        case ('c_signed_char', 'c_int8_t', 'c_int_least8_t', &
                'c_int_fast8_t', 'c_bool', 'c_char')
            kind_value = 1
        case ('c_short', 'c_int16_t', 'c_int_least16_t', 'c_int_fast16_t')
            kind_value = 2
        case ('c_int', 'c_int32_t', 'c_int_least32_t', 'c_int_fast32_t', &
                'c_float', 'c_float32')
            kind_value = 4
        case ('c_long', 'c_long_long', 'c_size_t', 'c_intptr_t', &
                'c_ptrdiff_t', 'c_intmax_t', 'c_int64_t', 'c_int_least64_t', &
                'c_int_fast64_t', 'c_double', 'c_float64')
            kind_value = 8
        case ('c_long_double', 'c_float128')
            kind_value = 16
        end select
    end function intrinsic_module_kind_value

    logical function use_list_contains(list, selector) result(found)
        type(string_t), allocatable, intent(in) :: list(:)
        character(len=*), intent(in) :: selector
        integer :: i

        found = .false.
        do i = 1, size(list)
            if (.not. allocated(list(i)%s)) cycle
            if (compact_lower(list(i)%s) == compact_lower(selector)) then
                found = .true.
                return
            end if
        end do
    end function use_list_contains

    logical function use_rename_contains(list, selector, remote) result(found)
        type(string_t), allocatable, intent(in) :: list(:)
        character(len=*), intent(in) :: selector
        character(len=:), allocatable, intent(out) :: remote
        integer :: i

        found = .false.
        remote = ''
        i = 1
        do while (i + 1 <= size(list))
            if (allocated(list(i)%s)) then
                if (compact_lower(list(i)%s) == compact_lower(selector)) then
                    if (allocated(list(i + 1)%s)) remote = list(i + 1)%s
                    found = .true.
                    return
                end if
            end if
            i = i + 2
        end do
    end function use_rename_contains

    recursive subroutine resolve_named_integer_constant(arena, reference_index, &
            name, value, visiting)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: reference_index
        character(len=*), intent(in) :: name
        integer, intent(out) :: value
        logical, intent(inout) :: visiting(:)
        type(declaration_binding_t) :: binding
        character(len=:), allocatable :: error_msg
        integer :: declaration_index

        value = 0
        call resolve_name_at_node(arena, reference_index, name, binding, error_msg)
        if (.not. binding%found) then
            ! Intrinsic module constants have no source declaration in the
            ! arena, but their values still participate in named parameters.
            if (resolve_intrinsic_module_kind(arena, reference_index, name, &
                value)) return
            return
        end if
        declaration_index = binding%declaration_node_index
        if (.not. arena%has_node_at(declaration_index)) return
        if (visiting(declaration_index)) return
        visiting(declaration_index) = .true.
        select type (decl => arena%entries(declaration_index)%node)
            type is (declaration_node)
            if (decl%has_initializer) then
                call evaluate_integer_constant(arena, decl%initializer_index, value, &
                    visiting)
            else if (decl%is_constant) then
                value = decl%constant_integer
            end if
        class default
            if (decl%is_constant) value = decl%constant_integer
        end select
        visiting(declaration_index) = .false.
    end subroutine resolve_named_integer_constant

    recursive subroutine evaluate_integer_constant(arena, expr_index, value, &
            visiting)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: expr_index
        integer, intent(out) :: value
        logical, intent(inout) :: visiting(:)
        integer :: lhs, rhs, ios, argument
        character(len=:), allocatable :: raw, name, operator

        value = 0
        if (.not. arena%has_node_at(expr_index)) return
        if (visiting(expr_index)) return
        visiting(expr_index) = .true.
        select type (expr => arena%entries(expr_index)%node)
            type is (literal_node)
            if (.not. allocated(expr%value)) then
                visiting(expr_index) = .false.
                return
            end if
            raw = trim(expr%value)
            if (index(raw, "_") > 0) raw = raw(:index(raw, "_") - 1)
            read (raw, *, iostat=ios) value
            if (ios /= 0) value = 0
            type is (identifier_node)
            if (allocated(expr%name)) then
                name = expr%name
                visiting(expr_index) = .false.
                call resolve_named_integer_constant(arena, expr_index, name, value, &
                    visiting)
                return
            end if
            type is (binary_op_node)
            lhs = 0
            rhs = 0
            if (expr%left_index > 0) then
                call evaluate_integer_constant(arena, expr%left_index, lhs, visiting)
            end if
            if (expr%right_index > 0) then
                call evaluate_integer_constant(arena, expr%right_index, rhs, visiting)
            end if
            operator = ""
            if (allocated(expr%operator)) operator = trim(expr%operator)
            select case (operator)
            case ("+")
                value = lhs + rhs
            case ("-")
                if (expr%left_index <= 0) then
                    value = -rhs
                else
                    value = lhs - rhs
                end if
            case ("*")
                value = lhs * rhs
            case ("/")
                if (rhs /= 0) value = lhs / rhs
            case ("**")
                if (rhs >= 0) value = lhs**rhs
            end select
            type is (call_or_subscript_node)
            if (.not. allocated(expr%name)) then
                visiting(expr_index) = .false.
                return
            end if
            select case (compact_lower(expr%name))
            case ("kind")
                ! KIND is a type inquiry, not evaluation of its argument data.
                if (allocated(expr%arg_indices)) then
                    if (size(expr%arg_indices) == 1) then
                        argument = expr%arg_indices(1)
                        if (arena%has_node_at(argument)) then
                            select type (arg => arena%entries(argument)%node)
                            type is (assignment_node)
                                if (arg%is_keyword_argument) argument = arg%value_index
                            end select
                        end if
                        if (arena%has_node_at(argument)) then
                            value = arena%entries(argument)%node%resolved_kind_value
                            ! Strict dummy checks can ask before annotation.
                            select type (arg => arena%entries(argument)%node)
                            type is (literal_node)
                                block
                                    type(literal_node) :: typed_literal
                                    typed_literal = arg
                                    call resolve_literal(arena, argument, typed_literal)
                                    value = typed_literal%resolved_kind_value
                                end block
                            end select
                        end if
                    end if
                end if
            case ("bit_size")
                ! BIT_SIZE is metadata-only; width follows the supported INTEGER kind.
                if (expr%is_intrinsic.and..not.expr%is_array_access.and.allocated(expr%arg_indices)) then
                    if (size(expr%arg_indices) == 1) then
                        argument = expr%arg_indices(1)
                        if (arena%has_node_at(argument)) then
                            select type (arg => arena%entries(argument)%node)
                            type is (assignment_node)
                                if (arg%is_keyword_argument) argument = arg%value_index
                            end select
                        end if
                        if (arena%has_node_at(argument)) then
                            value = arena%entries(argument)%node%resolved_kind_value
                            ! Strict dummy checks can ask before annotation.
                            select type (arg => arena%entries(argument)%node)
                            type is (literal_node)
                                block
                                    type(literal_node) :: typed_literal
                                    typed_literal = arg
                                    call resolve_literal(arena, argument, typed_literal)
                                    value = typed_literal%resolved_kind_value
                                end block
                            end select
                        end if
                    end if
                end if
                if (value==4.or.value==8) then
                    value=8*value
                else
                    value=0
                end if
            case ("selected_real_kind")
                call evaluate_selected_real_kind(arena, expr, value, visiting)
            case ("selected_int_kind")
                call evaluate_selected_int_kind(arena, expr, value, visiting)
            end select
        class default
            if (expr%is_constant) value = expr%constant_integer
        end select
        visiting(expr_index) = .false.
    end subroutine evaluate_integer_constant

    subroutine evaluate_selected_real_kind(arena, node, value, visiting)
        type(ast_arena_t), intent(in) :: arena
        type(call_or_subscript_node), intent(in) :: node
        integer, intent(out) :: value
        logical, intent(inout) :: visiting(:)
        integer :: requirements(3), slots(3), j, k, n, argument
        logical :: saw_keyword
        character(:), allocatable :: name

        value = 0
        requirements = [0, 0, 2]
        slots = 0
        saw_keyword = .false.
        n = 0
        if (allocated(node%arg_indices)) n = size(node%arg_indices)
        if (n > 3) return
        do j = 1, n
            argument = node%arg_indices(j)
            if (.not. arena%has_node_at(argument)) return
            k = j
            select type (arg => arena%entries(argument)%node)
            type is (assignment_node)
                if (.not. arg%is_keyword_argument) return
                saw_keyword = .true.
                if (.not. arena%has_node_at(arg%target_index)) return
                select type (target => arena%entries(arg%target_index)%node)
                type is (identifier_node)
                    if (.not. allocated(target%name)) return
                    name = compact_lower(target%name)
                class default
                    return
                end select
                select case (name)
                case ("p"); k = 1
                case ("r"); k = 2
                case ("radix"); k = 3
                case default; return
                end select
                argument = arg%value_index
            class default
                if (saw_keyword) return
            end select
            if (slots(k) /= 0) return
            slots(k) = argument
        end do
        do k = 1, 3
            if (slots(k) /= 0) then
                call evaluate_integer_constant(arena, slots(k), requirements(k), visiting)
            end if
        end do
        ! The frontend knows wider kinds than the restricted interpreter.
        if (requirements(3) /= 2) then
            value = -5
        else if (requirements(1) <= 6 .and. requirements(2) <= 37) then
            value = 4
        else if (requirements(1) <= 15 .and. requirements(2) <= 307) then
            value = 8
        else if (requirements(1) <= 33 .and. requirements(2) <= 4931) then
            value = 16
        else if (requirements(1) > 33 .and. requirements(2) > 4931) then
            value = -3
        else if (requirements(1) > 33) then
            value = -1
        else
            value = -2
        end if
    end subroutine evaluate_selected_real_kind

    subroutine evaluate_selected_int_kind(arena, node, value, visiting)
        type(ast_arena_t), intent(in) :: arena
        type(call_or_subscript_node), intent(in) :: node
        integer, intent(out) :: value
        logical, intent(inout) :: visiting(:)
        integer :: range_value

        value = 0
        range_value = 0
        if (.not. allocated(node%arg_indices)) return
        if (size(node%arg_indices) < 1) return
        call evaluate_integer_constant(arena, node%arg_indices(1), range_value, visiting)
        if (range_value <= 2) then
            value = 1
        else if (range_value <= 4) then
            value = 2
        else if (range_value <= 9) then
            value = 4
        else if (range_value <= 18) then
            value = 8
        else
            value = -1
        end if
    end subroutine evaluate_selected_int_kind

    subroutine real_result_kind_from_argument(arena, node, visiting, kind_value)
        type(ast_arena_t), intent(inout) :: arena
        type(call_or_subscript_node), intent(in) :: node
        logical, intent(inout) :: visiting(:)
        integer, intent(out) :: kind_value
        integer :: argument_type, argument_kind

        kind_value = 0
        call first_intrinsic_argument_metadata(arena, node, visiting, &
            argument_type, argument_kind)
        select case (argument_type)
        case (TCOMPLEX)
            kind_value = argument_kind
        end select
    end subroutine real_result_kind_from_argument

    subroutine resolve_real_round_metadata(arena,node,visiting)
        type(ast_arena_t),intent(inout)::arena
        type(call_or_subscript_node),intent(inout)::node
        logical,intent(inout)::visiting(:)
        integer::i,idx,kind_value
        logical::wanted
        if(.not.allocated(node%arg_indices))return
        do i=1,size(node%arg_indices)
            idx=node%arg_indices(i);wanted=i==1
            if(.not.arena%has_node_at(idx))cycle
            select type(arg=>arena%entries(idx)%node)
            type is(assignment_node)
                wanted=.false.
                if(.not.arg%is_keyword_argument)cycle
                if(.not.arena%has_node_at(arg%target_index))cycle
                select type(target=>arena%entries(arg%target_index)%node)
                type is(identifier_node)
                    wanted=to_lower(target%name)=='a'
                end select
                idx=arg%value_index
            end select
            if(.not.wanted.or..not.arena%has_node_at(idx))cycle
            call resolve_node_metadata(arena,idx,visiting)
            kind_value=intrinsic_kind_argument(arena,node,to_lower(node%name))
            if(kind_value<=0)kind_value=arena%entries(idx)%node%resolved_kind_value
            if(kind_value>0)call set_intrinsic_metadata(node,TREAL,kind_value,arena%entries(idx)%node%resolved_rank)
            return
        end do
    end subroutine
    subroutine decomposition_x_metadata(arena,node,visiting,kind_value)
        type(ast_arena_t),intent(inout)::arena
        type(call_or_subscript_node),intent(in)::node
        logical,intent(inout)::visiting(:)
        integer,intent(out)::kind_value
        integer::i,idx
        logical::wanted
        kind_value=0
        if(.not.allocated(node%arg_indices))return
        do i=1,size(node%arg_indices)
            idx=node%arg_indices(i);wanted=i==1
            if(.not.arena%has_node_at(idx))cycle
            select type(arg=>arena%entries(idx)%node)
            type is(assignment_node)
                wanted=.false.
                if(.not.arg%is_keyword_argument)cycle
                if(.not.arena%has_node_at(arg%target_index))cycle
                select type(target=>arena%entries(arg%target_index)%node)
                type is(identifier_node)
                    wanted=to_lower(target%name)=='x'
                end select
                idx=arg%value_index
            end select
            if(.not.wanted.or..not.arena%has_node_at(idx))cycle
            call resolve_node_metadata(arena,idx,visiting)
            kind_value=arena%entries(idx)%node%resolved_kind_value
            return
        end do
    end subroutine
    subroutine erf_bessel_x_metadata(arena,node,visiting,name,type_kind,kind_value)
        type(ast_arena_t),intent(inout)::arena
        type(call_or_subscript_node),intent(in)::node
        logical,intent(inout)::visiting(:)
        character(*),intent(in)::name
        integer,intent(out)::type_kind,kind_value
        integer::i,idx,position
        logical::wanted
        type_kind=0;kind_value=0;position=1
        if(name=='bessel_jn'.or.name=='bessel_yn')position=2
        if(.not.allocated(node%arg_indices))return
        do i=1,size(node%arg_indices)
            idx=node%arg_indices(i);wanted=i==position
            if(.not.arena%has_node_at(idx))cycle
            select type(arg=>arena%entries(idx)%node)
            type is(assignment_node)
                wanted=.false.
                if(.not.arg%is_keyword_argument)cycle
                if(.not.arena%has_node_at(arg%target_index))cycle
                select type(target=>arena%entries(arg%target_index)%node)
                type is(identifier_node)
                    wanted=to_lower(target%name)=='x'
                end select
                idx=arg%value_index
            end select
            if(.not.wanted.or..not.arena%has_node_at(idx))cycle
            call resolve_node_metadata(arena,idx,visiting)
            type_kind=normalize_type_kind(arena%entries(idx)%node%resolved_type_kind)
            kind_value=arena%entries(idx)%node%resolved_kind_value
            return
        end do
    end subroutine
    subroutine bit_i_argument_kind(arena,node,visiting,kind_value)
        type(ast_arena_t),intent(inout)::arena
        type(call_or_subscript_node),intent(in)::node
        logical,intent(inout)::visiting(:)
        integer,intent(out)::kind_value
        integer::j,idx
        logical::wanted
        kind_value=0
        if(.not.allocated(node%arg_indices))return
        do j=1,size(node%arg_indices)
            idx=node%arg_indices(j);wanted=j==1
            if(.not.arena%has_node_at(idx))cycle
            select type(arg=>arena%entries(idx)%node)
            type is(assignment_node)
                wanted=.false.
                if(.not.arg%is_keyword_argument)cycle
                if(.not.arena%has_node_at(arg%target_index))cycle
                select type(target=>arena%entries(arg%target_index)%node)
                type is(identifier_node)
                    wanted=to_lower(target%name)=='i'
                end select
                idx=arg%value_index
            end select
            if(.not.wanted.or..not.arena%has_node_at(idx))cycle
            call resolve_node_metadata(arena,idx,visiting)
            kind_value=arena%entries(idx)%node%resolved_kind_value
            return
        end do
    end subroutine bit_i_argument_kind
    subroutine first_intrinsic_argument_metadata(arena, node, visiting, &
            type_kind, kind_value)
        type(ast_arena_t), intent(inout) :: arena
        type(call_or_subscript_node), intent(in) :: node
        logical, intent(inout) :: visiting(:)
        integer, intent(out) :: type_kind, kind_value
        integer :: argument_index

        type_kind = 0
        kind_value = 0
        if (.not. allocated(node%arg_indices)) return
        if (size(node%arg_indices) <= 0) return
        argument_index = node%arg_indices(1)
        if (.not. arena%has_node_at(argument_index)) return
        call resolve_node_metadata(arena, argument_index, visiting)
        if (.not. arena%has_node_at(argument_index)) return
        type_kind = normalize_type_kind( &
            arena%entries(argument_index)%node%resolved_type_kind)
        kind_value = arena%entries(argument_index)%node%resolved_kind_value
    end subroutine first_intrinsic_argument_metadata

    integer function intrinsic_kind_argument(arena, node, intrinsic_name) &
            result(value)
        type(ast_arena_t), intent(in) :: arena
        type(call_or_subscript_node), intent(in) :: node
        character(len=*), intent(in) :: intrinsic_name
        logical, allocatable :: visiting(:)
        integer :: argument_index, argument_position

        value = 0
        if (.not. allocated(node%arg_indices)) return
        argument_position = kind_argument_position(arena, node, intrinsic_name)
        if (argument_position <= 0) return
        if (argument_position > size(node%arg_indices)) return
        if (arena%size <= 0) return
        argument_index = node%arg_indices(argument_position)
        if (.not. arena%has_node_at(argument_index)) return
        select type (argument => arena%entries(argument_index)%node)
            type is (assignment_node)
            argument_index = argument%value_index
        end select
        if (.not. arena%has_node_at(argument_index)) return
        allocate (visiting(arena%size), source=.false.)
        call evaluate_integer_constant(arena, argument_index, value, visiting)
    end function intrinsic_kind_argument

    integer function kind_argument_position(arena, node, intrinsic_name) &
            result(position)
        type(ast_arena_t), intent(in) :: arena
        type(call_or_subscript_node), intent(in) :: node
        character(len=*), intent(in) :: intrinsic_name
        integer :: second_argument, i, argument_index

        position = 0
        if (.not. allocated(node%arg_indices)) return
        select case (intrinsic_name)
        case ("real", "aint", "anint", "char", "achar", "iachar", "nint", "floor", "ceiling", "index", "scan", "verify", "len_trim", "shape", "maskl", "maskr")
            do i = 1, size(node%arg_indices)
                argument_index = node%arg_indices(i)
                if (.not. arena%has_node_at(argument_index)) cycle
                select type (argument => arena%entries(argument_index)%node)
                type is (assignment_node)
                    if (.not. argument%is_keyword_argument) cycle
                    if (.not. arena%has_node_at(argument%target_index)) cycle
                    select type (target => arena%entries(argument%target_index)%node)
                    type is (identifier_node)
                        if (to_lower(target%name) == "kind") then
                            position = i
                            return
                        end if
                    end select
                class default
                    if (intrinsic_name == "index" .or. intrinsic_name == "scan" .or. intrinsic_name == "verify") then
                        if (i == 4) position = i
                    else
                        if (i == 2) position = i
                    end if
                end select
            end do
        case ("cmplx")
            if (size(node%arg_indices) >= 3) then
                position = 3
                return
            end if
            if (size(node%arg_indices) /= 2) return
            second_argument = node%arg_indices(2)
            if (.not. arena%has_node_at(second_argument)) return
            select type (argument => arena%entries(second_argument)%node)
                type is (assignment_node)
                position = 2
            end select
        case default
            if (size(node%arg_indices) >= 2) position = 2
        end select
    end function kind_argument_position

    integer pure function numeric_result_type(left_type, right_type) result(kind_id)
        integer, intent(in) :: left_type, right_type

        kind_id = 0
        if (left_type == TCOMPLEX .or. right_type == TCOMPLEX) then
            kind_id = TCOMPLEX
        else if (left_type == TREAL .or. right_type == TREAL) then
            kind_id = TREAL
        else if (left_type == TINT .and. right_type == TINT) then
            kind_id = TINT
        end if
    end function numeric_result_type

    integer pure function numeric_result_kind(result_type, left_type, left_kind, &
            right_type, right_kind) result(kind_value)
        integer, intent(in) :: result_type, left_type, left_kind
        integer, intent(in) :: right_type, right_kind

        kind_value = 0
        select case (result_type)
        case (TINT)
            kind_value = max(left_kind, right_kind)
        case (TREAL)
            if (left_type == TREAL) kind_value = max(kind_value, left_kind)
            if (right_type == TREAL) kind_value = max(kind_value, right_kind)
        case (TCOMPLEX)
            if (left_type == TCOMPLEX .or. left_type == TREAL) then
                kind_value = max(kind_value, left_kind)
            end if
            if (right_type == TCOMPLEX .or. right_type == TREAL) then
                kind_value = max(kind_value, right_kind)
            end if
        end select
    end function numeric_result_kind

    logical pure function is_relational_operator(operator) result(is_relational)
        character(len=*), intent(in) :: operator

        select case (operator)
        case ("==", "/=", "<", "<=", ">", ">=", ".eq.", ".ne.", &
                ".lt.", ".le.", ".gt.", ".ge.")
            is_relational = .true.
        case default
            is_relational = .false.
        end select
    end function is_relational_operator

    logical pure function is_logical_operator(operator) result(is_logical)
        character(len=*), intent(in) :: operator

        select case (operator)
        case (".and.", ".or.", ".not.", ".eqv.", ".neqv.")
            is_logical = .true.
        case default
            is_logical = .false.
        end select
    end function is_logical_operator

    logical function declaration_has_name(arena, node_index, name) result(has_name)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: node_index
        character(len=*), intent(in) :: name
        integer :: i

        has_name = .false.
        if (.not. arena%has_node_at(node_index)) return
        select type (decl => arena%entries(node_index)%node)
            type is (declaration_node)
            if (allocated(decl%var_name)) then
                if (compact_lower(decl%var_name) == compact_lower(name)) then
                    has_name = .true.
                    return
                end if
            end if
            if (.not. allocated(decl%var_names)) return
            do i = 1, size(decl%var_names)
                if (compact_lower(decl%var_names(i)) /= compact_lower(name)) cycle
                has_name = .true.
                return
            end do
            type is (parameter_declaration_node)
            if (allocated(decl%name)) then
                has_name = compact_lower(decl%name) == compact_lower(name)
            end if
        end select
    end function declaration_has_name

    function compact_lower(text) result(compact)
        character(len=*), intent(in) :: text
        character(len=:), allocatable :: compact
        character(len=:), allocatable :: lowered
        integer :: i, count

        lowered = to_lower(trim(adjustl(text)))
        count = 0
        do i = 1, len(lowered)
            if (lowered(i:i) == " ") cycle
            if (lowered(i:i) == achar(9)) cycle
            count = count + 1
        end do
        allocate (character(len=count) :: compact)
        count = 0
        do i = 1, len(lowered)
            if (lowered(i:i) == " ") cycle
            if (lowered(i:i) == achar(9)) cycle
            count = count + 1
            compact(count:count) = lowered(i:i)
        end do
    end function compact_lower

end module frontend_compiler_type_queries
