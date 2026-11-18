! SPDX-License-Identifier: MIT
program test_internal_read_producer
    use fortfront_compiler
    use ast_nodes_io,only:read_statement_node
    implicit none
    character(*),parameter::nl=new_line('a')
    character(70)::statements(5)=[character(70)::'read(text,*) n', &
        'read(unit=text,fmt=*,iostat=stat) n','read(text,"(i2)") n', &
        'read(text,fmt) n','read(10) n']
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    integer::i,j,found,checks
    checks=0
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    do j=1,5
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            'character(10)::text,fmt'//nl//'integer::n,stat'//nl// &
            trim(statements(j))//nl//'end program',front,opts)
        if(.not.front%success()) error stop 'READ producer rejected'
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(read_statement_node)
                if(node%is_formatted.neqv.(j/=5)) error stop 'READ formatted flag differs'
                checks=checks+1
                if(.not.allocated(node%specifiers).or..not.allocated(node%var_indices)) &
                    error stop 'READ controls/items missing'
                if(size(node%var_indices)/=1) error stop 'READ item count differs'
                if(node%specifiers(1)%name/='unit'.or.node%specifiers(1)%value_node_index<=0) &
                    error stop 'READ source file identity missing'
                checks=checks+1
                if(j==2) then
                    if(size(node%specifiers)/=3) error stop 'READ status missing'
                    if(node%specifiers(3)%name/='iostat'.or.node%iostat_var_index<=0.or. &
                       node%iostat_var_index/=node%specifiers(3)%value_node_index) &
                        error stop 'READ status source identity differs'
                    checks=checks+1
                else if(node%iostat_var_index/=0) then
                    error stop 'READ unexpected status'
                end if
                found=found+1
            end select
        end do
        if(found/=1) error stop 'READ producer count differs'
    end do
    print *, 'internal READ producer checks passed:',checks
end program
