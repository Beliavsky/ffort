! SPDX-License-Identifier: MIT
program test_generic_intrinsic_repeat
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fortfront_compiler
    use fortfront_ast,only:call_or_subscript_node
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(compiler_frontend_result_t)::front
    type(compiler_frontend_options_t)::opts
    type(resolved_type_query_t)::typ
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source
    integer::which,e,i,checks,found,g
    checks=0
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    source=fixture(.false.)
    call compile_frontend_from_string(source,front,opts)
    call expect(front%success(),'strict producer accepts intrinsic generic extension')
    found=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i))cycle
        select type(node=>front%arena%entries(i)%node)
        type is(call_or_subscript_node)
            if(node%name/='repeat')cycle
            typ=query_resolved_type(front%arena,i)
            call expect(typ%found.and.typ%type_kind==TCHAR.and.typ%kind_value==1.and.typ%rank==0,'intrinsic result metadata')
            call expect(node%is_intrinsic,'intrinsic fallback classification')
            found=found+1
        end select
    end do
    call expect(found==1,'producer call count')
    do which=1,5
        call parse_subset(source,p,d)
        call expect(d%code==0,'source guard accepts generic fallback')
        e=0
        do i=1,p%ne
            if(p%expressions(i)%op=='repeat')e=i
        end do
        call expect(e>0,'intrinsic IR located')
        select case(which)
        case(2);p%expressions(e)%generic_id=1
        case(3);p%expressions(e)%args=p%expressions(e)%args([2,1])
        case(4);p%expressions(e)%op='trim'
        case(5);p%expressions(e)%character_len=9
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(which==1),'adapter fallback/mutation')
    end do
    source=fixture(.true.)
    call parse_subset(source,p,d)
    call expect(d%code==0,'source guard preserves matching specific')
    e=0
    do i=1,p%ne
        if(p%expressions(i)%kind==ex_user_call.and.p%expressions(i)%generic_id>0)e=i
    end do
    call expect(e>0,'matching user generic located')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'adapter accepts matching user generic')
    ! Same scalar CHARACTER result length as intrinsic REPEAT: only independent
    ! scope/specific resolution can catch this forged intrinsic substitution.
    p%expressions(e)%kind=ex_call;p%expressions(e)%symbol=0
    p%expressions(e)%generic_id=0;p%expressions(e)%op='repeat'
    call verify_frontend(source,p,d)
    call expect(d%code/=0,'adapter rejects fallback over matching user specific')
    print *, 'PASS: generic/intrinsic REPEAT producer and adapter assertions:',checks
contains
    function fixture(overlap) result(text)
        logical,intent(in)::overlap
        character(:),allocatable::text,args
        args='n,text'
        if(overlap)args='text,n'
        text='module m'//nl//'implicit none'//nl//'interface repeat'//nl// &
            'module procedure custom'//nl//'end interface'//nl//'contains'//nl// &
            'function custom('//args//') result(answer)'//nl// &
            'integer,intent(in)::n'//nl//'character(*),intent(in)::text'//nl// &
            'character(3)::answer'//nl//"answer='USR'"//nl//'end function'//nl//'end module'//nl// &
            'program main'//nl//'use m'//nl//'implicit none'//nl// &
            "print '(a)',repeat('x',3)"//nl//'end program'
    end function
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label
        if(allocated(d%message))print *,d%message
        if(allocated(front%error_msg))print *,front%error_msg
        error stop 1
    end subroutine
end program
