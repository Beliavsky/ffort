! SPDX-License-Identifier: MIT
program test_lexical_producer
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
    call check_call('lge',"lge('a','b')",TLOGICAL,0,4)
    call check_call('lge',"lge(string_b=['a','b'],string_a='a')",TLOGICAL,1,4)
    call check_call('lge',"lge(reshape(['a'],[1,1]),'b')",TLOGICAL,2,4)
    call check_call('lge',"lge('b',reshape(['a'],[1,1,1]))",TLOGICAL,3,4)
    call check_shadowed_array('lge')
    call check_call('lgt',"lgt('a','b')",TLOGICAL,0,4)
    call check_call('lgt',"lgt(string_b=['a','b'],string_a='a')",TLOGICAL,1,4)
    call check_call('lgt',"lgt(reshape(['a'],[1,1]),'b')",TLOGICAL,2,4)
    call check_call('lgt',"lgt('b',reshape(['a'],[1,1,1]))",TLOGICAL,3,4)
    call check_shadowed_array('lgt')
    call check_call('lle',"lle('a','b')",TLOGICAL,0,4)
    call check_call('lle',"lle(string_b=['a','b'],string_a='a')",TLOGICAL,1,4)
    call check_call('lle',"lle(reshape(['a'],[1,1]),'b')",TLOGICAL,2,4)
    call check_call('lle',"lle('b',reshape(['a'],[1,1,1]))",TLOGICAL,3,4)
    call check_shadowed_array('lle')
    call check_call('llt',"llt('a','b')",TLOGICAL,0,4)
    call check_call('llt',"llt(string_b=['a','b'],string_a='a')",TLOGICAL,1,4)
    call check_call('llt',"llt(reshape(['a'],[1,1]),'b')",TLOGICAL,2,4)
    call check_call('llt',"llt('b',reshape(['a'],[1,1,1]))",TLOGICAL,3,4)
    call check_shadowed_array('llt')
    print *, 'PASS: independent lexical intrinsic producer cases:',checks
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
            error stop 'lexical intrinsic producer compile failure'
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
                if(.not.node%is_intrinsic.or.node%is_array_access.or..not.typ%found.or.typ%type_kind/=type_kind.or.typ%kind_value/=kind_value.or.typ%rank/=rank)then
                    print *,expression,typ%found,typ%type_kind,typ%kind_value,typ%rank
                    error stop 'lexical intrinsic producer metadata differs'
                end if
            end select
        end do
        if(found/=1)error stop 'lexical intrinsic producer node missing or duplicated'
        checks=checks+1
    end subroutine
end program
