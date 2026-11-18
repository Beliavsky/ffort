! SPDX-License-Identifier: MIT
program test_character_arrays_producer
    use fortfront_compiler
    use ast_nodes_core, only: array_literal_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    integer::i,j,found
    character(24)::constructors(4)=[character(24):: &
        '[character(2)::]', '(/character(2)::/)', '[character::]', '(/character::/)']
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    do j=1,4
        call compile_frontend_from_string('program p'//nl//'character(2)::a(0)'//nl// &
            'a='//trim(constructors(j))//nl//'print *,a'//nl//'end program',front,opts)
        if(.not.front%success()) then
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'empty CHARACTER constructor frontend failure'
        end if
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(array_literal_node)
                if(.not.allocated(node%element_indices).or..not.allocated(node%type_spec)) &
                    error stop 'empty typed array metadata absent'
                if(size(node%element_indices)/=0) error stop 'empty typed array elements differ'
                if(j<=2) then
                    if(node%type_spec/='character(2)') error stop 'typed length lost'
                else
                    if(node%type_spec/='character') error stop 'default CHARACTER type lost'
                end if
                found=found+1
            end select
        end do
        if(found/=1) error stop 'empty typed constructor absent or duplicated'
    end do
    print '(a)','PASS: four empty CHARACTER constructor producer shapes and type specifications'
end program
