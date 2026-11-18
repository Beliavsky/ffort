! SPDX-License-Identifier: MIT
program test_repeat_intrinsic_producer
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
    call check_call('repeat',"repeat('ab',3)",TCHAR,0,1)
    call check_call('repeat',"repeat(string='ab',ncopies=3_8)",TCHAR,0,1)
    call check_call('repeat',"repeat(ncopies=0,string='ab')",TCHAR,0,1)
    call check_call('repeat',"repeat('',3)",TCHAR,0,1)
    call check_call('repeat',"repeat(s,n)",TCHAR,0,1,'character(3)::s'//nl//'integer::n')
    call check_shadowed_array('repeat')
    call check_shadowed_procedure(.false.)
    call check_shadowed_procedure(.true.)
    print *, 'PASS: independent REPEAT intrinsic producer cases:',checks
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
    subroutine check_shadowed_procedure(generic)
        logical,intent(in)::generic
        character(:),allocatable::source,name
        integer::i,found
        source='module m'//nl
        name='repeat'
        if(generic)then
            source=source//'interface repeat'//nl//'module procedure f'//nl//'end interface'//nl
            name='f'
        end if
        source=source//'contains'//nl//'integer function '//name//'(x)'//nl// &
            'integer,intent(in)::x'//nl//name//'=x+1'//nl//'end function'//nl// &
            'end module'//nl//'program p'//nl//'use m'//nl//'implicit none'//nl// &
            'print *,repeat(2)'//nl//'end program'
        call compile_frontend_from_string(source,front,opts)
        if(.not.front%success())error stop 'shadow procedure compile failure'
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(node=>front%arena%entries(i)%node)
            type is(call_or_subscript_node)
                if(.not.allocated(node%name))cycle
                if(node%name/='repeat')cycle
                found=found+1
                typ=query_resolved_type(front%arena,i)
                if(node%is_intrinsic.or.node%is_array_access.or..not.typ%found.or. &
                    typ%type_kind/=TINT.or.typ%kind_value/=4.or.typ%rank/=0) then
                    print *, 'generic=',generic,' intrinsic/array/found=', &
                        node%is_intrinsic,node%is_array_access,typ%found
                    print *, 'type/kind/rank=',typ%type_kind,typ%kind_value,typ%rank
                    error stop 'shadow procedure metadata differs'
                end if
            end select
        end do
        if(found/=1)error stop 'shadow procedure call missing'
        checks=checks+1
    end subroutine
    subroutine check_call(name,expression,type_kind,rank,kind_value,declarations)
        character(*),intent(in)::name,expression
        integer,intent(in)::type_kind,rank,kind_value
        character(*),optional,intent(in)::declarations
        character(:),allocatable::prefix
        integer::i,found
        prefix=''
        if(present(declarations))prefix=declarations//nl
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl//prefix// &
            'print *,'//expression//nl//'end program',front,opts)
        if(.not.front%success()) then
            print *,expression
            if(allocated(front%error_msg))print *,front%error_msg
            error stop 'REPEAT intrinsic producer compile failure'
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
                    error stop 'REPEAT intrinsic producer metadata differs'
                end if
            end select
        end do
        if(found/=1)error stop 'REPEAT intrinsic producer node missing or duplicated'
        checks=checks+1
    end subroutine
end program
