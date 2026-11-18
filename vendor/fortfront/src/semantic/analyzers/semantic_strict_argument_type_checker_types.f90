module semantic_strict_argument_type_checker_types
    use ast_base, only: LITERAL_INTEGER, LITERAL_LOGICAL, LITERAL_REAL, &
        LITERAL_STRING
    use ast_arena_modern, only: ast_arena_t
    use ast_nodes_core, only: assignment_node, identifier_node, literal_node, &
        call_or_subscript_node
    use ast_nodes_bounds, only: array_slice_node, range_expression_node, array_bounds_node
    use ast_nodes_data, only: declaration_node, parameter_declaration_node
    use ast_nodes_procedure, only: function_def_node
    use frontend_compiler_resolution, only: declaration_binding_t, &
        resolve_identifier_binding, resolve_name_at_node
    use frontend_compiler_type_queries, only: resolve_kind_selector, resolve_kind_expression, &
        resolve_expression_type, resolved_type_query_t
    use semantic_elemental_validation, only: is_elemental_prefix
    use semantic_procedure_utils, only: declaration_type_to_mono
    use semantic_unsigned_integer_mix_diagnostics, only: extract_integer_signedness
    use string_utils_mod, only: to_lower
    use type_system_unified, only: mono_type_t, create_mono_type, TARRAY, TDOUBLE, &
        TCHAR, TCOMPLEX, TINT, TLOGICAL, TREAL, TVAR
    implicit none
    private

    public :: strict_actual_argument_type
    public :: strict_dummy_type
    public :: strict_type_is_known
    public :: strict_type_name
    public :: strict_types_match

contains

    function strict_dummy_type(arena, decl_index) result(typ)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: decl_index
        type(mono_type_t) :: typ
        integer :: rank, i
        typ%kind = 0
        if (.not. arena%has_node_at(decl_index)) return

        select type (node => arena%entries(decl_index)%node)
            type is (parameter_declaration_node)
            if (.not. allocated(node%type_name)) return
            typ = declaration_type_to_mono(node%type_name)
            call apply_declared_real_kind(arena, decl_index, node%type_name, &
                node%has_kind, node%kind_value, typ)
            if (typ%kind == TCHAR) then
                if (allocated(node%character_length_expr)) then
                    call apply_declared_character_length(node%character_length_expr, typ)
                else
                    typ = create_mono_type(TCHAR, char_size=1)
                end if
            end if
            if (node%is_unsigned) then
                if (typ%kind == TINT) then
                    typ%is_unsigned = .true.
                end if
            end if
            if (node%is_array) then
                rank = 1
                if (allocated(node%dimension_indices)) rank = size(node%dimension_indices)
                do i = 1, rank
                    typ = create_mono_type(TARRAY, args=[typ])
                end do
            end if
            type is (declaration_node)
            if (allocated(node%type_name)) then
                typ = declaration_type_to_mono(node%type_name)
                call apply_declared_real_kind(arena, decl_index, node%type_name, &
                    node%has_kind, node%kind_value, typ)
            else
                typ = node%inferred_type
            end if
            if (typ%kind == TCHAR) then
                if (allocated(node%character_length_expr)) then
                    call apply_declared_character_length(node%character_length_expr, typ)
                else
                    typ = create_mono_type(TCHAR, char_size=1)
                end if
            end if
            if (node%is_unsigned) then
                if (typ%kind == TINT) then
                    typ%is_unsigned = .true.
                end if
            end if
            if (node%is_array .and. typ%kind /= TARRAY) then
                rank = 1
                if (allocated(node%dimension_indices)) rank = size(node%dimension_indices)
                do i = 1, rank
                    typ = create_mono_type(TARRAY, args=[typ])
                end do
            end if
        class default
            typ = arena%entries(decl_index)%node%inferred_type
        end select
    end function strict_dummy_type

    ! declaration_type_to_mono retains the CHARACTER tag but drops its LEN.
    ! Preserve literal/default lengths before wrapping the type in array ranks;
    ! otherwise a declared length-two dummy is incorrectly compared as length 0.
    subroutine apply_declared_character_length(expression, typ)
        character(len=*), intent(in) :: expression
        type(mono_type_t), intent(inout) :: typ
        character(len=:), allocatable :: text
        integer :: i, first, length_value, ios
        ! A nonliteral length is unresolved here, not a known zero length.
        ! Its value/storage compatibility is checked independently at runtime.
        typ = create_mono_type(TCHAR, char_size=-1)
        text = ""
        do i = 1, len_trim(expression)
            if (expression(i:i) /= ' ') text = text//expression(i:i)
        end do
        if (text == '*' .or. text == ':') then
            typ = create_mono_type(TCHAR, char_size=-1)
            return
        end if
        if (len(text) == 0) return
        first = 1
        if (text(1:1) == '+' .or. text(1:1) == '-') first = 2
        if (first > len(text)) return
        if (verify(text(first:), '0123456789') /= 0) return
        read (text, *, iostat=ios) length_value
        if (ios == 0) typ = create_mono_type(TCHAR, char_size=max(0, length_value))
    end subroutine apply_declared_character_length

    recursive function strict_actual_argument_type(arena, expr_index) result(typ)
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: expr_index
        type(mono_type_t) :: typ, declared_type, actual_type
        type(resolved_type_query_t) :: resolved, bound_resolved
        integer :: rank, i, bound
        logical :: inferred_integer, inferred_unsigned
        type(declaration_binding_t) :: binding
        character(len=:), allocatable :: error_msg

        typ%kind = 0
        if (.not. arena%has_node_at(expr_index)) return

        ! Resolve the complete expression from scope-aware declaration metadata,
        ! not the provisional inference type. Named-kind array expressions can
        ! otherwise still carry default REAL here, before final annotation.
        resolved = resolve_expression_type(arena, expr_index)
        if (resolved%found .and. resolved%rank >= 0) then
            select case (resolved%type_kind)
            case (TREAL, TLOGICAL, TCHAR)
                typ = create_mono_type(resolved%type_kind)
                if (resolved%type_kind == TREAL .and. resolved%kind_value == 8) &
                    typ = create_mono_type(TDOUBLE)
                if (resolved%type_kind == TCHAR) then
                    declared_type = arena%entries(expr_index)%node%inferred_type
                    ! Resolve designator lengths from their own declaration,
                    ! not a provisional inferred length from another scope.
                    select type (node => arena%entries(expr_index)%node)
                    type is (identifier_node)
                        call resolve_identifier_binding(arena, expr_index, binding, error_msg)
                        if (binding%found) declared_type = strict_dummy_type(arena, binding%declaration_node_index)
                    type is (call_or_subscript_node)
                        if (allocated(node%name)) then
                            call resolve_name_at_node(arena, expr_index, node%name, binding, error_msg)
                            if (binding%found) then
                                if (arena%has_node_at(binding%declaration_node_index)) then
                                    select type (decl => arena%entries(binding%declaration_node_index)%node)
                                    type is (declaration_node)
                                        declared_type = strict_dummy_type(arena, binding%declaration_node_index)
                                    end select
                                end if
                            end if
                        end if
                    type is (array_slice_node)
                        if (.not. node%is_character_substring) &
                            declared_type = strict_actual_argument_type(arena, node%array_index)
                    end select
                    call declared_type%sync_from_arena()
                    do while (declared_type%kind == TARRAY)
                        if (.not. declared_type%has_args()) exit
                        declared_type = declared_type%get_arg(1)
                        call declared_type%sync_from_arena()
                    end do
                    if (declared_type%kind == TCHAR) typ = declared_type
                end if
                do i = 1, resolved%rank
                    typ = create_mono_type(TARRAY, args=[typ])
                end do
                return
            end select
        end if

        select type (node => arena%entries(expr_index)%node)
            type is (literal_node)
            typ = strict_literal_type(arena, expr_index, node)
            type is (identifier_node)
            ! Inference may not yet have visited this scope. A declared scalar
            ! actual has its declaration's type and kind, including aliases.
            typ = node%inferred_type
            call resolve_identifier_binding(arena, expr_index, binding, error_msg)
            if (binding%found) then
                if (arena%has_node_at(binding%declaration_node_index)) then
                    select type (decl => &
                            arena%entries(binding%declaration_node_index)%node)
                    type is (declaration_node)
                        block
                            declared_type = strict_dummy_type(arena, &
                                binding%declaration_node_index)
                            if (strict_type_is_known(declared_type)) typ = declared_type
                        end block
                    end select
                end if
            end if
            type is (call_or_subscript_node)
            typ = node%inferred_type
            if (.not. allocated(node%name)) return
            call resolve_name_at_node(arena, expr_index, node%name, binding, error_msg)
            if (binding%found) then
                if (arena%has_node_at(binding%declaration_node_index)) then
                    select type (func => &
                            arena%entries(binding%declaration_node_index)%node)
                    type is (declaration_node)
                        if (func%is_array) then
                            declared_type = strict_dummy_type(arena, binding%declaration_node_index)
                            call declared_type%sync_from_arena()
                            do while (declared_type%kind == TARRAY)
                                if (.not. declared_type%has_args()) exit
                                declared_type = declared_type%get_arg(1)
                                call declared_type%sync_from_arena()
                            end do
                            if (strict_type_is_known(declared_type)) typ = with_element_type(typ, declared_type)
                        end if
                    type is (function_def_node)
                        if (allocated(func%return_type)) then
                            declared_type = declaration_type_to_mono(func%return_type)
                            call apply_declared_real_kind(arena, &
                                binding%declaration_node_index, func%return_type, &
                                .false., 0, declared_type)
                            if (strict_type_is_known(declared_type)) then
                                typ = declared_type
                                if (is_elemental_prefix(func%prefix_keywords) .and. &
                                    allocated(node%arg_indices)) then
                                    do i = 1, size(node%arg_indices)
                                        actual_type = strict_actual_argument_type(arena, &
                                            node%arg_indices(i))
                                        if (actual_type%kind /= TARRAY) cycle
                                        typ = with_element_type(actual_type, declared_type)
                                        exit
                                    end do
                                end if
                            end if
                        end if
                    end select
                end if
            end if
            type is (array_slice_node)
            typ = node%inferred_type
            if (.not. node%is_character_substring) then
                declared_type = strict_actual_argument_type(arena, node%array_index)
                call declared_type%sync_from_arena()
                do while (declared_type%kind == TARRAY)
                    if (.not. declared_type%has_args()) exit
                    declared_type = declared_type%get_arg(1)
                    call declared_type%sync_from_arena()
                end do
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
                        bound_resolved = resolve_expression_type(arena, bound)
                        if (bound_resolved%found .and. bound_resolved%type_kind == TINT .and. &
                            bound_resolved%rank == 1) rank = rank + 1
                    end select
                end do
                if (strict_type_is_known(declared_type) .and. rank > 0) then
                    typ = declared_type
                    do i = 1, rank
                        typ = create_mono_type(TARRAY, args=[typ])
                    end do
                end if
            end if
            type is (assignment_node)
            if (node%is_keyword_argument) then
                typ = strict_actual_argument_type(arena, node%value_index)
            else
                typ = node%inferred_type
            end if
        class default
            typ = arena%entries(expr_index)%node%inferred_type
        end select

        ! Parameter-array expressions may also retain provisional REAL in the
        ! inference tree. Rebuild INTEGER kind/rank from the canonical resolver,
        ! retaining signedness from the existing strict/inferred element path.
        if (resolved%found .and. resolved%type_kind == TINT .and. resolved%rank >= 0) then
            call extract_integer_signedness(typ, inferred_integer, inferred_unsigned)
            typ = create_mono_type(TINT)
            typ%is_unsigned = inferred_integer .and. inferred_unsigned
            do i = 1, resolved%rank
                typ = create_mono_type(TARRAY, args=[typ])
            end do
        end if
    end function strict_actual_argument_type

    recursive function with_element_type(shape, element) result(typ)
        type(mono_type_t), intent(in) :: shape, element
        type(mono_type_t) :: typ, copy, child
        copy = shape
        call copy%sync_from_arena()
        typ = element
        if (copy%kind /= TARRAY) return
        if (.not. copy%has_args()) then
            typ = shape
            return
        end if
        child = with_element_type(copy%get_arg(1), element)
        typ = create_mono_type(TARRAY, args=[child], array_size=copy%size)
    end function with_element_type

    function strict_literal_type(arena, expr_index, node) result(typ)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: expr_index
        type(literal_node), intent(in) :: node
        type(mono_type_t) :: typ
        character(len=:), allocatable :: lowered
        integer :: kind_value, underscore_pos

        typ%kind = 0
        if (.not. allocated(node%value)) return

        select case (node%literal_kind)
        case (LITERAL_INTEGER)
            typ = create_mono_type(TINT)
        case (LITERAL_LOGICAL)
            typ = create_mono_type(TLOGICAL)
        case (LITERAL_STRING)
            typ = create_mono_type(TCHAR)
        case (LITERAL_REAL)
            lowered = to_lower(trim(node%value))
            underscore_pos = index(lowered, '_')
            kind_value = 4
            if (underscore_pos > 0 .and. underscore_pos < len_trim(lowered)) then
                kind_value = resolve_kind_selector(arena, expr_index, &
                    lowered(underscore_pos + 1:))
            else if (index(lowered, 'd') > 0) then
                kind_value = 8
            end if
            if (kind_value == 8) then
                typ = create_mono_type(TDOUBLE)
            else
                typ = create_mono_type(TREAL)
            end if
        case default
            typ%kind = 0
        end select
    end function strict_literal_type

    subroutine apply_declared_real_kind(arena, decl_index, type_name, &
            has_kind, explicit_kind, typ)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: decl_index, explicit_kind
        character(len=*), intent(in) :: type_name
        logical, intent(in) :: has_kind
        type(mono_type_t), intent(inout) :: typ
        character(len=:), allocatable :: selector
        integer :: open_pos, close_pos, equal_pos, kind_value

        if (typ%kind /= TREAL) return
        kind_value = 4
        if (has_kind .and. explicit_kind > 0) then
            kind_value = explicit_kind
        else
            open_pos = index(type_name, '(')
            close_pos = index(type_name, ')', back=.true.)
            if (open_pos > 0 .and. close_pos > open_pos) then
                selector = trim(adjustl(type_name(open_pos + 1:close_pos - 1)))
                equal_pos = index(selector, '=')
                if (equal_pos > 0) selector = trim(adjustl(selector(equal_pos + 1:)))
                kind_value = resolve_kind_selector(arena, decl_index, selector)
            end if
        end if
        if (kind_value <= 0) then
            select type (decl => arena%entries(decl_index)%node)
            type is (declaration_node)
                if (decl%kind_selector_index > 0) &
                    kind_value = resolve_kind_expression(arena, decl%kind_selector_index)
            end select
        end if
        if (kind_value == 8) typ = create_mono_type(TDOUBLE)
    end subroutine apply_declared_real_kind

    recursive logical function strict_types_match(expected, actual) result(matches)
        type(mono_type_t), intent(in) :: expected
        type(mono_type_t), intent(in) :: actual
        type(mono_type_t) :: expected_copy
        type(mono_type_t) :: actual_copy

        matches = .false.
        expected_copy = expected
        actual_copy = actual
        call expected_copy%sync_from_arena()
        call actual_copy%sync_from_arena()

        if (expected_copy%kind == TARRAY) then
            if (actual_copy%kind /= TARRAY) return
            if (.not. expected_copy%has_args()) return
            if (.not. actual_copy%has_args()) return
            matches = strict_types_match(expected_copy%get_arg(1), &
                actual_copy%get_arg(1))
            return
        end if

        matches = expected_copy%kind == actual_copy%kind
        if (matches .and. expected_copy%kind == TCHAR) then
            matches = expected_copy%size < 0 .or. actual_copy%size < 0 .or. &
                expected_copy%size == actual_copy%size
        end if
    end function strict_types_match

    logical function strict_type_is_known(typ) result(is_known)
        type(mono_type_t), intent(in) :: typ
        type(mono_type_t) :: copy

        is_known = .false.
        copy = typ
        call copy%sync_from_arena()
        if (copy%kind <= 0) return
        if (copy%kind == TVAR) return
        is_known = .true.
    end function strict_type_is_known

    recursive subroutine strict_type_name(typ, name)
        type(mono_type_t), intent(in) :: typ
        character(len=:), allocatable, intent(out) :: name
        type(mono_type_t) :: copy
        character(len=64) :: buffer
        character(len=:), allocatable :: element_name
        integer :: rank

        copy = typ
        call copy%sync_from_arena()

        select case (copy%kind)
        case (TINT)
            name = "integer"
        case (TREAL)
            name = "real"
        case (TDOUBLE)
            name = "real(dp)"
        case (TLOGICAL)
            name = "logical"
        case (TCHAR)
            if (copy%size > 0) then
                write (buffer, '("character(len=", I0, ")")') copy%size
                name = trim(buffer)
            else
                name = "character"
            end if
        case (TCOMPLEX)
            name = "complex"
        case (TARRAY)
            rank = 0
            do while (copy%kind == TARRAY)
                rank = rank + 1
                if (.not. copy%has_args()) exit
                copy = copy%get_arg(1)
                call copy%sync_from_arena()
            end do
            element_name = 'unknown'
            if (copy%kind /= TARRAY) call strict_type_name(copy, element_name)
            write (buffer, '(I0)') rank
            name = 'rank-'//trim(buffer)//' array of '//element_name
        case default
            name = "unknown"
        end select
    end subroutine strict_type_name

end module semantic_strict_argument_type_checker_types
