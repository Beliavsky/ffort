! SPDX-License-Identifier: MIT
program test_stdout_write_producer
    use fortfront_compiler
    use ast_nodes_io,only:write_statement_node
    implicit none
    character(*),parameter::nl=new_line('a')
    character(64)::statements(4)=[character(64)::'write(*,*)','write(*,*)1', &
        'write(*,"(i0)")1','write(*,"(2(i0,1x))")1,2']
    integer::counts(4)=[0,1,1,2]
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    integer::i,j,found
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    do j=1,4
        call compile_frontend_from_string('program main'//nl//'implicit none'//nl// &
            trim(statements(j))//nl//'end program',front,opts)
        if(.not.front%success())error stop 'stdout WRITE producer rejected'
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(node=>front%arena%entries(i)%node)
            type is(write_statement_node)
                if(.not.allocated(node%unit_spec).or..not.allocated(node%format_spec).or. &
                   .not.allocated(node%specifiers))error stop 'WRITE controls missing'
                if(node%unit_spec/='*'.or.size(node%specifiers)/=2)error stop 'WRITE unit/control count differs'
                if(node%specifiers(1)%name/='unit'.or.node%specifiers(1)%value/='*'.or. &
                   node%specifiers(2)%name/='fmt'.or.node%specifiers(2)%value/=node%format_spec) &
                    error stop 'WRITE control metadata differs'
                if(node%format_expr_index/=0.or.node%iostat_var_index/=0.or.node%err_label_index/=0.or. &
                   node%end_label_index/=0)error stop 'WRITE unexpected control metadata'
                if(allocated(node%arg_indices)) then
                    if(size(node%arg_indices)/=counts(j))error stop 'WRITE item count differs'
                else if(counts(j)/=0) then
                    error stop 'WRITE item metadata absent'
                end if
                found=found+1
            end select
        end do
        if(found/=1)error stop 'WRITE producer node count differs'
    end do
    print *, 'PASS: stdout WRITE independent producer metadata:',4
end program
