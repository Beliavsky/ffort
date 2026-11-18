module semantic_kind_selector_validation
    use ast_arena_modern, only: ast_arena_t
    use ast_nodes_data, only: declaration_node
    use ast_nodes_core, only: call_or_subscript_node
    use error_handling, only: error_collection_t, ERROR_SEMANTIC
    use string_utils_mod, only: to_lower
    implicit none
    private
    public :: validate_kind_selectors

contains

    subroutine validate_kind_selectors(arena, errors)
        type(ast_arena_t), intent(in) :: arena
        type(error_collection_t), intent(inout) :: errors
        integer :: i

        do i = 1, arena%size
            if (.not. arena%has_node_at(i)) cycle
            select type (node => arena%entries(i)%node)
            type is (declaration_node)
                call check_kind_selector(arena, node%kind_selector_index, errors)
            end select
        end do
    end subroutine validate_kind_selectors

    subroutine check_kind_selector(arena, selector_index, errors)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: selector_index
        type(error_collection_t), intent(inout) :: errors

        ! A kind selector is a scalar integer constant expression. Intrinsics
        ! generally require arguments. SELECTED_REAL_KIND is the exception:
        ! since Fortran 2008 its P, R and RADIX arguments may all be absent.
        ! Other empty calls cannot be parameter-array elements or valid inquiries.
        ! Calls inside inquiry arguments are deliberately not traversed: their
        ! types can be inquired about without evaluating their values.
        if (.not. arena%has_node_at(selector_index)) return
        select type (node => arena%entries(selector_index)%node)
        type is (call_or_subscript_node)
            if (allocated(node%arg_indices)) then
                if (size(node%arg_indices) /= 0) return
            end if
            if (.not. allocated(node%name)) return
            if (to_lower(node%name) == "selected_real_kind") return
            call errors%add_error( &
                "Zero-argument function '"//node%name// &
                "' is not permitted in a constant kind selector", &
                code=ERROR_SEMANTIC, component="semantic_kind_selector", &
                line=node%line, column=node%column, end_line=node%line, &
                end_column=node%column + len_trim(node%name))
        end select
    end subroutine check_kind_selector

end module semantic_kind_selector_validation
