! SPDX-License-Identifier: MIT
program test_output_implied_do_producer
    use fortfront_compiler
    use ast_nodes_io,only:io_implied_do_node
    use ast_nodes_core,only:call_or_subscript_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    integer::i,j,k,loops,calls,checks,children(3)
    checks=0
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
        'character(4)::strs(3)'//nl//'integer::i,j,trim(3)'//nl// &
        'print "(*(a))",((strs(j),j=size(strs),i,-1),i=1,3)'//nl// &
        'print *, (trim(i),i=1,size(trim))'//nl//'end program',front,opts)
    call expect(front%success(),'producer accepts nested output lists')
    loops=0;calls=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(node=>front%arena%entries(i)%node)
        type is(io_implied_do_node)
            loops=loops+1
            call expect(allocated(node%var_name).and.allocated(node%object_indices),'controls and objects retained')
            call expect(size(node%object_indices)==1,'object count retained')
            call expect(node%expr_index==node%object_indices(1),'first object retained')
            do j=1,size(node%object_indices)
                k=node%object_indices(j)
                call expect(front%arena%entries(k)%parent_index==i,'object parent link')
            end do
            children=[node%start_expr_index,node%end_expr_index,node%step_expr_index]
            do j=1,3
                k=children(j)
                if(j==3.and.k==0) cycle
                call expect(front%arena%has_node_at(k),'control index retained')
                call expect(front%arena%entries(k)%parent_index==i,'control parent link')
            end do
        type is(call_or_subscript_node)
            if(.not.allocated(node%name)) cycle
            if(node%name=='strs'.or.node%name=='trim') then
                calls=calls+1
                call expect(node%is_array_access.and..not.node%is_intrinsic,'array binding including intrinsic shadow')
                call expect(node%resolved_type_found.and.node%resolved_rank==0,'scalar element metadata')
            end if
        end select
    end do
    call expect(loops==3.and.calls==2,'producer node counts')
    print *, 'output implied-DO producer checks passed:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(.not.ok) then
            print *, 'FAIL ',label
            error stop 1
        end if
    end subroutine
end program
