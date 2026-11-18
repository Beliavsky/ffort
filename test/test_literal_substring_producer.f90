! SPDX-License-Identifier: MIT
program test_literal_substring_producer
    use fortfront_compiler
    use fortfront_ast, only: subroutine_call_node, literal_node
    use ast_nodes_bounds, only: array_slice_node,range_expression_node
    use ast_base,only:LITERAL_STRING
    use type_system_unified, only: TCHAR
    implicit none
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    character(*),parameter::nl=new_line('a')
    integer::j,n,k,b,r
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.true.
    call check("'abcd'(1:2)")
    call check("'abcd'(i:j)")
    call check("'abcd'(:)")
    call check("'abcd'(3:2)")
    call check("'a''b'(2:3)")
    call check("''(:)")
    print '(a)','PASS: six literal substring producer structures and scalar type inquiries'
contains
    subroutine check(actual)
        character(*),intent(in)::actual
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            'integer::i=1,j=2'//nl// &
            'call take('//actual//')'//nl//'contains'//nl// &
            'subroutine take(x)'//nl//'character(*),intent(in)::x'//nl// &
            'end subroutine'//nl//'end program',front,opts)
        if(.not.front%success()) then
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'literal substring producer rejected source'
        end if
        k=0
        do j=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(j)) cycle
            select type(node=>front%arena%entries(j)%node)
            type is(subroutine_call_node)
                if(node%name/='take') cycle
                n=node%arg_indices(1)
                typ=query_resolved_type(front%arena,n)
                if(.not.typ%found.or.typ%rank/=0.or.typ%type_kind/=TCHAR.or.typ%kind_value/=1) &
                    error stop 'wrong literal substring producer type/rank'
                select type(slice=>front%arena%entries(n)%node)
                type is(array_slice_node)
                    if(slice%num_dimensions/=1) error stop 'substring dimensions lost'
                    b=slice%array_index;r=slice%bounds_indices(1)
                    select type(base=>front%arena%entries(b)%node)
                    type is(literal_node)
                        if(base%literal_kind/=LITERAL_STRING) error stop 'substring base kind lost'
                    class default
                        error stop 'substring literal base lost'
                    end select
                    select type(bounds=>front%arena%entries(r)%node)
                    type is(range_expression_node)
                        if(bounds%stride_index/=0) error stop 'unexpected substring stride'
                    class default
                        error stop 'substring range lost'
                    end select
                class default
                    error stop 'substring folded away or changed'
                end select
                k=k+1
            end select
        end do
        if(k/=1) error stop 'missing substring CALL'
    end subroutine
end program
