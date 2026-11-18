! SPDX-License-Identifier: MIT
program test_scalar_allocatable_character
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser, only:parse_subset
    use fi_frontend, only:verify_frontend
    use fi_runtime, only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'character(:),allocatable::s,t'//nl//'integer::status'//nl// &
        'allocate(character(3)::s,t,stat=status)'//nl// &
        'if(status/=0.or..not.allocated(s).or.len(s)/=3) error stop 1'//nl// &
        "s(:)='abc'"//nl//"s=s//'d'"//nl// &
        "if(len(s)/=4.or.s/='abcd') error stop 2"//nl// &
        "t=''"//nl//'if(.not.allocated(t).or.len(t)/=0) error stop 3'//nl// &
        'deallocate(s,t)'//nl//'if(allocated(s).or.allocated(t)) error stop 4'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::s,which,j,checks,first,assigned,whole,idx
    integer(int64)::budget
    checks=0
    do which=1,37
        call baseline()
        select case(which)
        case(2);p%symbols(s)%typ=ty_integer
        case(3);p%symbols(s)%real_kind=8
        case(4);p%symbols(s)%rank=1
        case(5);p%symbols(s)%rank=-1
        case(6);p%symbols(s)%rank=4
        case(7);p%symbols(s)%is_parameter=.true.
        case(8);p%symbols(s)%is_pointer=.true.
        case(9);p%symbols(s)%is_saved=.true.
        case(10);p%symbols(s)%is_automatic=.true.
        case(11);p%symbols(s)%assumed_shape=.true.
        case(12);p%symbols(s)%is_class=.true.
        case(13);p%symbols(s)%is_intrinsic=.true.
        case(14);p%symbols(s)%initializer_expr=1
        case(15);p%symbols(s)%kind_expr=1
        case(16);p%symbols(s)%parameter_ready=.true.
        case(17);allocate(p%symbols(s)%constant_values(0))
        case(18);p%symbols(s)%character_len=-2
        case(19);p%symbols(s)%character_len=65537
        case(20);p%symbols(s)%length_expr=p%ne+1
        case(21);p%symbols(s)%length_expr=-1
        case(22);p%symbols(s)%lower_bound=0
        case(23);p%symbols(s)%upper_bound=0
        case(24);p%symbols(s)%lower_bound2=0
        case(25);p%symbols(s)%upper_bound2=2
        case(26);p%symbols(s)%lower_bound3=0
        case(27);p%symbols(s)%upper_bound3=2
        case(28);p%symbols(s)%lower_expr=1
        case(29);p%symbols(s)%upper_expr2=1
        case(30);p%symbols(s)%lower_expr3=1
        case(31);p%symbols(s)%deferred_character=.false.
        case(32);p%symbols(s)%character_len=3
        case(33);p%symbols(s)%is_dummy=.true.
        case(34);p%symbols(s)%is_optional=.true.
        case(35);p%symbols(s)%dummy_intent=1
        case(36);p%symbols(s)%scope=p%np+1
        case(37);p%symbols(s)%is_allocatable=.false.
        end select
        call verify_frontend(source,p,d)
        call expectation(which==1,'adapter declaration',which)
        d=diagnostic_t()
        call execute_program(p,d)
        call expectation(which==1,'runtime declaration',which)
    end do
    do which=1,33
        call baseline()
        select case(which)
        case(2);p%code(first)%items=[1]
        case(3);p%code(first)%b=p%ne+1
        case(4);p%code(first)%b=0
        case(5);p%code(first)%c=65
        case(6);p%code(first)%d=2
        case(7);p%code(first)%target=first
        case(8);p%code(first+1)%symbol=s
        case(9);p%code(first+1)%b=0
        case(10);p%code(first+1)%scope=1
        case(11);p%code(first+1)%items=[1,2]
        case(12);p%expressions(whole)%extent=-1_int64
        case(13);p%expressions(whole)%rank=1
        case(14);p%expressions(whole)%scope=1
        case(15);p%code(assigned)%b=1
        case(16);p%code(assigned)%third=1
        case(17);p%expressions(whole)%character_len=7
        case(18);p%expressions(whole)%dims=[1_int64,0_int64,0_int64]
        case(19);p%expressions(whole)%typ=ty_integer
        case(20);p%expressions(whole)%real_kind=8
        case(21);p%expressions(whole)%left=1
        case(22);p%expressions(whole)%right=1
        case(23);p%expressions(whole)%stride=1
        case(24);p%expressions(whole)%left2=1
        case(25);p%expressions(whole)%length_expr=1
        case(26);p%expressions(whole)%generic_id=1
        case(27);p%expressions(whole)%bound_type=1
        case(28);p%expressions(whole)%bound_binding=1
        case(29);p%expressions(whole)%intrinsic_mask=1
        case(30);p%expressions(whole)%op='bogus'
        case(31);allocate(p%expressions(whole)%args(0))
        case(32);p%expressions(whole)%triplet(2)=.true.
        case(33);p%expressions(whole)%constructor_kind_expr=1
        end select
        call verify_frontend(source,p,d)
        call expectation(which==1,'adapter instruction',which)
        d=diagnostic_t()
        call execute_program(p,d)
        call expectation(which==1,'runtime instruction',which)
    end do
    call baseline()
    call verify_frontend(source,p,d)
    call expectation(.true.,'clean baseline',0)
    do j=1,3
        d=diagnostic_t()
        call execute_program(p,d)
        call expectation(.true.,'root lifetime reset',j)
    end do
    budget=4;d=diagnostic_t()
    call execute_program(p,d,max_steps=budget)
    call expectation(.false.,'budget interruption',0)
    d=diagnostic_t()
    call execute_program(p,d)
    call expectation(.true.,'root reset after interruption',0)
    print '(a,i0,a)','scalar allocatable CHARACTER: ',checks,' checks passed'
contains
    subroutine baseline()
        d=diagnostic_t()
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'scalar CHARACTER baseline parse failed'
        end if
        s=0;first=0;assigned=0;whole=0
        do idx=1,p%ns
            if(p%symbols(idx)%name=='s')s=idx
        end do
        do idx=1,p%nc
            if(p%code(idx)%op==op_allocate.and.first==0)first=idx
            if(p%code(idx)%op==op_assign.and.p%code(idx)%symbol==s.and.p%code(idx)%c==0)assigned=idx
        end do
        do idx=1,p%ne
            if(p%expressions(idx)%kind==ex_variable.and.p%expressions(idx)%symbol==s)whole=idx
        end do
        if(min(s,first,assigned,whole)<=0)error stop 'missing scalar test metadata'
    end subroutine
    subroutine expectation(success,where,case_number)
        logical,intent(in)::success
        character(*),intent(in)::where
        integer,intent(in)::case_number
        checks=checks+1
        if((d%code==0).neqv.success) then
            print *,where,case_number,d%code
            if(allocated(d%message)) print *,d%message
            error stop 'scalar CHARACTER expectation failed'
        end if
    end subroutine
end program
