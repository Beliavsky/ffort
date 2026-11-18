! SPDX-License-Identifier: MIT
program test_character_intrinsics_producer
    use fortfront_compiler
    use fortfront_ast,only:call_or_subscript_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    integer::checks
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.true.
    checks=0
    call check_call('index',"index('ab','b')",TINT,0,4)
    call check_call('index',"index('ab','b',kind=8)",TINT,0,8)
    call check_call('index',"index(kind=8,string='ab',substring='b')",TINT,0,8)
    call check_call('index',"index('aba','a',.true.,8)",TINT,0,8)
    call check_call('index',"index(['ab','ba'],'a')",TINT,1,4)
    call check_call('index',"index('aba','a',[.false.,.true.],kind=8)",TINT,1,8)
    call check_call('index',"index(reshape(['ab','ba'],[1,2]),'a')",TINT,2,4)
    call check_call('index',"index('aba','a',kind=16)",TINT,0,16)
    call check_call('len_trim',"len_trim('a ')",TINT,0,4)
    call check_call('len_trim',"len_trim(string='a ',kind=8)",TINT,0,8)
    call check_call('len_trim',"len_trim(kind=8,string=['a ','bb'])",TINT,1,8)
    call check_call('len_trim',"len_trim(reshape(['a ','bb'],[1,2]),8)",TINT,2,8)
    call check_call('adjustl',"adjustl(' a')",TCHAR,0,1)
    call check_call('adjustl',"adjustl(string=[' a',' b'])",TCHAR,1,1)
    call check_call('adjustl',"adjustl(reshape([' a',' b'],[1,2]))",TCHAR,2,1)
    call check_call('adjustr',"adjustr('a ')",TCHAR,0,1)
    call check_call('adjustr',"adjustr(string=['a ','b '])",TCHAR,1,1)
    call check_call('adjustr',"adjustr(reshape(['a ','b '],[1,2]))",TCHAR,2,1)
    call check_shadowed_array('index')
    call check_shadowed_array('len_trim')
    call check_shadowed_array('adjustl')
    call check_shadowed_array('adjustr')
    print *, 'PASS: independent character intrinsic producer cases:',checks
contains
    subroutine check_shadowed_array(name)
        character(*),intent(in)::name
        integer::i,found
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            'integer::'//name//'(2)=[11,12]'//nl//'print *,'//name//'(2)'//nl//'end program',front,opts)
        if(.not.front%success())error stop 'shadowed intrinsic array producer compile failure'
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(node=>front%arena%entries(i)%node)
            type is(call_or_subscript_node)
                if(.not.allocated(node%name))cycle
                if(node%name/=name)cycle
                found=found+1
                typ=query_resolved_type(front%arena,i)
                if(node%is_intrinsic.or..not.node%is_array_access.or..not.typ%found.or. &
                   typ%type_kind/=TINT.or.typ%kind_value/=4.or.typ%rank/=0) &
                    error stop 'shadowed intrinsic array producer binding differs'
            end select
        end do
        if(found/=1)error stop 'shadowed intrinsic array producer node missing'
        checks=checks+1
    end subroutine
    subroutine check_call(name,expression,type_kind,rank,kind_value)
        character(*),intent(in)::name,expression
        integer,intent(in)::type_kind,rank,kind_value
        integer::i,found
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            'print *,'//expression//nl//'end program',front,opts)
        if(.not.front%success()) then
            print *,expression
            if(allocated(front%error_msg))print *,front%error_msg
            error stop 'character intrinsic producer compile failure'
        end if
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(node=>front%arena%entries(i)%node)
            type is(call_or_subscript_node)
                if(.not.allocated(node%name))cycle
                if(node%name/=name)cycle
                found=found+1
                typ=query_resolved_type(front%arena,i)
                if(.not.typ%found.or.typ%type_kind/=type_kind.or.typ%kind_value/=kind_value.or.typ%rank/=rank)then
                    print *,expression,typ%found,typ%type_kind,typ%kind_value,typ%rank
                    error stop 'character intrinsic producer metadata differs'
                end if
            end select
        end do
        if(found/=1)error stop 'character intrinsic producer node missing or duplicated'
        checks=checks+1
    end subroutine
end program
