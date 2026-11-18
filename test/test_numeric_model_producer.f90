! SPDX-License-Identifier: MIT
program test_numeric_model_producer
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
    call check_call('epsilon',"epsilon(0.0)",TREAL,0,4)
    call check_call('epsilon',"epsilon(x=[0.0d0,1.0d0])",TREAL,0,8)
    call check_call('tiny',"tiny(0.0d0)",TREAL,0,8)
    call check_call('tiny',"tiny(reshape([1.0,2.0],[1,2]))",TREAL,0,4)
    call check_call('huge',"huge(1_8)",TINT,0,8)
    call check_call('huge',"huge([1,2])",TINT,0,4)
    call check_call('huge',"huge(x=reshape([1.0d0,2.0d0],[1,1,2]))",TREAL,0,8)
    call check_call('radix',"radix(0_8)",TINT,0,4)
    call check_call('radix',"radix(x=[1.0d0,2.0d0])",TINT,0,4)
    call check_shadowed_array('epsilon')
    call check_shadowed_array('tiny')
    call check_shadowed_array('huge')
    call check_shadowed_array('radix')
    print *, 'PASS: independent numeric model intrinsic producer cases:',checks
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
            error stop 'numeric model intrinsic producer compile failure'
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
                    error stop 'numeric model intrinsic producer metadata differs'
                end if
            end select
        end do
        if(found/=1)error stop 'numeric model intrinsic producer node missing or duplicated'
        checks=checks+1
    end subroutine
end program
