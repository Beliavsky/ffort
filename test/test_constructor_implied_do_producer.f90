! SPDX-License-Identifier: MIT
! Native producer coverage for vendor patch 0090. No interpreter dependency.
program test_constructor_implied_do_producer
    use fortfront_compiler
    use ast_nodes_core, only: array_literal_node, identifier_node, &
        binary_op_node, call_or_subscript_node
    use ast_nodes_loops, only: do_loop_node
    use type_system_unified, only: TINT, TREAL, TLOGICAL, TCHAR, TARRAY
    use semantic_implied_do_validation, only: is_array_constructor_implied_do
    implicit none
    character(*), parameter :: nl = new_line('a')
    type(compiler_frontend_options_t) :: opts
    type(compiler_frontend_result_t) :: front
    integer :: checks

    checks = 0
    opts%input_mode = INPUT_MODE_STANDARD
    opts%operating_mode = OPERATING_MODE_STRICT
    opts%standardize = .false.
    opts%run_semantics = .true.
    call check_integer('[0_8,(i,-i,i=1,2),9_8,(j,j=2,1,-1)]', [2,1], 4, 8)
    call check_integer('(/0_8,(i,-i,i=1,2),9_8,(j,j=2,1,-1)/)', [2,1], 4, 8)
    call check_integer('[0_8,((i+j,-j,j=1,2),i,i=1,2),9_8]', [2,2], 3, 8)
    call check_integer('(/0_8,((i+j,-j,j=1,2),i,i=1,2),9_8/)', [2,2], 3, 8)
    call check_integer('[(v,i,i=2,1,-1),v]', [2], 2, 8)
    call check_integer('(/(v,i,i=2,1,-1),v/)', [2], 2, 8)
    call check_integer('[([i,2_8],(/j,4_8/),j=1,2)]', [2], 1, 8)
    call check_integer('(/([i,2_8],(/j,4_8/),j=1,2)/)', [2], 1, 8)
    call check_integer('[(i,i=2,1),5_8]', [1], 2, 8)
    call check_integer('[0,(i,-i,i=1,2),9,(j,j=2,1,-1)]', [2,1], 4, 4)
    call check_integer('[(i,i=1,kind(i))]', [1], 1, 8)
    call check_integer('[(i,i=1,kind(i+1_8))]', [1], 1, 8)
    call check_integer('[(i,i=1,digits(i+1_8))]', [1], 1, 8)
    call check_integer('[(i,i=1,radix(i+1_8))]', [1], 1, 8)
    call check_integer('[(i,i=1,huge(i+1_8))]', [1], 1, 8)
    call check_expression('[0.0_8,(real(i,8),-real(i,8),i=1,2)]', &
        'integer::i,j'//nl//'real(8),allocatable::a(:)', [2], 2, TREAL, 8)
    call check_expression('[(all(v/=i),i=1,2)]', &
        'integer::i,j,v(2)'//nl//'logical,allocatable::a(:)', [1], 1, TLOGICAL, 4)
    call check_expression("[character(3)::'a',(']', '(', i=1,2),'/']", &
        'integer::i,j'//nl//'character(3),allocatable::a(:)', [2], 3, TCHAR, 1)
    call check_expression("(/character(3)::'a',(']', '(', i=1,2),'/ '/)", &
        'integer::i,j'//nl//'character(3),allocatable::a(:)', [2], 3, TCHAR, 1)
    call check_expression('[(sum(i),i=1,2)]', &
        'integer::i,j,sum(2)'//nl//'integer,allocatable::a(:)', [1], 1, TINT, 4)
    call check_malformed('[(i,i=1)]')
    call check_malformed('[(i,i=,2)]')
    call check_malformed('[(i,i=1,)]')
    call check_malformed('[(i,i=1,2,)]')
    call check_malformed('[(i,i=1,2,1,2)]')
    call check_malformed('[(i,i=1,2),]')
    call check_malformed('[(i,i=1,2) 3]')
    call check_malformed('[1,(i,j,3)]')
    call check_malformed('[(i,,i=1,2)]')
    call check_malformed('(/(i,i=1,2),/)')
    call check_malformed('[(i,i=i,2)]')
    call check_malformed('[(i,i=1,kind(i)+i)]')
    call check_malformed('[((i,i=1,2),i=1,2)]')
    call check_executable_loop()
    print '(a,i0)', 'PASS: constructor implied-DO producer checks: ', checks
contains
    subroutine check_integer(expression, body_counts, root_count, kind_value)
        character(*), intent(in) :: expression
        integer, intent(in) :: body_counts(:), root_count, kind_value
        character(1) :: kind_text
        write (kind_text, '(i1)') kind_value
        call check_expression(expression, 'integer('//kind_text//')::i,j,v(2)'//nl// &
            'integer('//kind_text//'),allocatable::a(:)', &
            body_counts, root_count, TINT, kind_value)
    end subroutine check_integer

    subroutine check_expression(expression, declarations, body_counts, root_count, &
            type_kind, kind_value)
        character(*), intent(in) :: expression, declarations
        integer, intent(in) :: body_counts(:), root_count, type_kind, kind_value
        integer :: i, j, k, loops, roots, last_column, body, children(3), index_kind
        type(declaration_binding_t) :: binding
        character(:), allocatable :: diagnostic
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            declarations//nl//'a='//expression//nl//'print *,i,j'//nl//'end program', front, opts)
        if (.not. front%success()) then
            print *, expression
            if (allocated(front%error_msg)) print *, front%error_msg
        end if
        call expect(front%success(), 'valid constructor accepted')
        loops = 0
        roots = 0
        do i = 1, front%arena%entry_count
            if (.not. front%arena%has_node_at(i)) cycle
            select type (node => front%arena%entries(i)%node)
            type is (do_loop_node)
                loops = loops + 1
                call expect(loops <= size(body_counts), 'no extra implied-DO nodes')
                call expect(is_array_constructor_implied_do(front%arena, i), &
                    'constructor ancestry retained')
                call expect(allocated(node%body_indices), 'body list allocated')
                call expect(size(node%body_indices) == body_counts(loops), 'body item count')
                call expect(node%line == 5 .and. node%column >= 3, 'loop source line and column')
                call expect(expression(node%column-2:node%column-2) == '(', 'actual loop opening location')
                call expect(node%resolved_type_found, 'exact loop type available')
                call expect(node%resolved_type_kind == type_kind, 'loop body element type')
                call expect(node%resolved_kind_value == kind_value, 'loop body element kind')
                call expect(node%resolved_rank == 1, 'loop result rank one')
                call expect(node%inferred_type%kind == TARRAY, 'loop inferred array type')
                last_column = 0
                do j = 1, size(node%body_indices)
                    body = node%body_indices(j)
                    call expect(front%arena%has_node_at(body), 'body item exists')
                    call expect(front%arena%entries(body)%parent_index == i, 'body parent link')
                    call expect(front%arena%entries(body)%node%column > last_column, 'body source order')
                    last_column = front%arena%entries(body)%node%column
                end do
                children = [node%start_expr_index,node%end_expr_index,node%step_expr_index]
                do j = 1, 3
                    k = children(j)
                    if (j == 3 .and. k == 0) cycle
                    call expect(front%arena%has_node_at(k), 'bound expression exists')
                    call expect(front%arena%entries(k)%parent_index == i, 'bound parent link')
                end do
            type is (array_literal_node)
                if (node%line /= 5 .or. node%column /= 3) cycle
                roots = roots + 1
                call expect(size(node%element_indices) == root_count, 'ordered outer item count')
                call expect(node%resolved_type_found, 'exact constructor type available')
                call expect(node%resolved_type_kind == type_kind, 'constructor element type')
                call expect(node%resolved_kind_value == kind_value, 'constructor element kind')
                call expect(node%resolved_rank == 1, 'constructor result rank one')
                do j = 1, size(node%element_indices)
                    k = node%element_indices(j)
                    call expect(front%arena%entries(k)%parent_index == i, 'constructor item parent')
                end do
            type is (identifier_node)
                if (.not. allocated(node%name)) cycle
                if (node%name /= 'i' .and. node%name /= 'j') cycle
                call resolve_identifier_binding(front%arena, i, binding, diagnostic)
                call expect(binding%found, 'index source declaration binding retained')
                call expect(node%resolved_type_kind == TINT .and. node%resolved_rank == 0, &
                    'index retains scalar INTEGER type')
                index_kind = 4
                if (index(declarations, 'integer(8)::') > 0) index_kind = 8
                call expect(node%resolved_kind_value == index_kind, 'index declared kind retained')
            type is (binary_op_node)
                if (node%left_index /= 0) &
                    call expect(front%arena%has_node_at(node%left_index), 'complete binary left operand')
                call expect(front%arena%has_node_at(node%right_index), 'complete binary right operand')
            type is (call_or_subscript_node)
                if (.not. allocated(node%name)) cycle
                if (node%name == 'sum') then
                    call expect(node%is_array_access .and. .not. node%is_intrinsic, &
                        'intrinsic-spelled array binding retained')
                end if
            end select
        end do
        call expect(loops == size(body_counts), 'exact implied-DO count')
        call expect(roots == 1, 'one complete outer constructor')
    end subroutine check_expression

    subroutine check_malformed(expression)
        character(*), intent(in) :: expression
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            'integer::i,j'//nl//'integer,allocatable::a(:)'//nl// &
            'a='//expression//nl//'end program', front, opts)
        if (front%success()) print *, 'Unexpected acceptance: ', expression
        call expect(.not. front%success(), 'malformed/invalid implied-DO refused')
    end subroutine check_malformed

    subroutine check_executable_loop()
        integer :: i, count
        call compile_frontend_from_string('program p'//nl//'integer::i'//nl// &
            'do i=1,2'//nl//'print *,i'//nl//'end do'//nl//'end program', front, opts)
        call expect(front%success(), 'ordinary executable DO preserved')
        count = 0
        do i = 1, front%arena%entry_count
            if (.not. front%arena%has_node_at(i)) cycle
            select type (node => front%arena%entries(i)%node)
            type is (do_loop_node)
                count = count + 1
                call expect(.not. is_array_constructor_implied_do(front%arena, i), &
                    'executable DO never classified as constructor')
            end select
        end do
        call expect(count == 1, 'one executable DO retained')
    end subroutine check_executable_loop

    subroutine expect(ok, label)
        logical, intent(in) :: ok
        character(*), intent(in) :: label
        checks = checks + 1
        if (.not. ok) then
            print *, 'FAIL: ', label
            error stop 1
        end if
    end subroutine expect
end program test_constructor_implied_do_producer
