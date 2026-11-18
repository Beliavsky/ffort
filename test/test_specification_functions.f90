! SPDX-License-Identifier: MIT
program test_specification_functions
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl//'integer::state'//nl//'contains'//nl// &
        'pure integer function g(n) result(v)'//nl//'integer,intent(in)::n'//nl//'v=n+1'//nl//'end function'//nl// &
        'pure integer function f(n) result(v)'//nl//'integer,intent(in)::n'//nl//'v=g(n)'//nl//'end function'//nl// &
        'subroutine work(n)'//nl//'integer,intent(in)::n'//nl//'integer::a(f(n))'//nl// &
        'character(len=f(n))::s'//nl//'a=7'//nl//"s='abcd'"//nl// &
        'if(size(a)/=n+1.or.len(s)/=n+1) error stop 1'//nl//'end subroutine'//nl//'end module'//nl// &
        'program p'//nl//'use m'//nl//'implicit none'//nl//'call work(3)'//nl//'end program'
    integer::which,stage,j,f,g,bound,arg,dummy,res,arr,chars,assign,checks,scope
    integer(int64)::budget
    checks=0
    do stage=1,2
        do which=1,29
            call baseline()
            select case(which)
            case(2);p%procedures(f)%is_pure=.false.
            case(3);p%procedures(f)%has_pure_prefix=.false.
            case(4);p%procedures(f)%has_impure_prefix=.true.
            case(5);p%procedures(f)%is_recursive=.true.
            case(6);p%procedures(f)%module_id=0
            case(7);p%procedures(f)%is_subroutine=.true.
            case(8);p%expressions(bound)%symbol=0
            case(9);p%expressions(bound)%generic_id=1
            case(10);p%expressions(bound)%bound_type=1
            case(11);p%expressions(bound)%bound_binding=1
            case(12);p%expressions(bound)%op='+' 
            case(13);p%expressions(bound)%real_kind=8
            case(14);p%expressions(bound)%rank=1
            case(15);p%expressions(bound)%args(1)=0
            case(16);p%expressions(arg)%real_kind=8
            case(17);p%expressions(arg)%scope=0
            case(18);p%symbols(dummy)%dummy_intent=3
            case(19);p%symbols(dummy)%is_optional=.true.
            case(20);p%symbols(dummy)%scope=g
            case(21);p%symbols(dummy)%is_dummy=.false.
            case(22);p%symbols(dummy)%is_allocatable=.true.
            case(23);p%symbols(dummy)%rank=1
            case(24);p%symbols(res)%rank=1
            case(25);p%symbols(res)%real_kind=16
            case(26);p%symbols(res)%scope=g
            case(27);p%symbols(res)%is_parameter=.true.
            case(28);p%procedures(g)%is_pure=.false.
            case(29);p%code(assign)%symbol=1 ! Forbidden mutable-module write in PURE g.
            end select
            if(stage==1) then
                call verify_frontend(source,p,d)
            else
                call execute_program(p,d,max_steps=1000_int64)
            end if
            checks=checks+1
            if((which==1.and.d%code/=0).or.(which/=1.and.d%code==0)) then
                print *,stage,which,d%code
                if(allocated(d%message)) print *,d%message
                error stop 'specification function mutation admitted'
            end if
            if(stage==2.and.which/=1.and.d%code/=2) error stop 'wrong runtime error class'
        end do
    end do
    call baseline()
    budget=3_int64
    call execute_program(p,d,budget_remaining=budget)
    if(d%code/=2.or.budget/=0_int64) error stop 'specification call did not share budget'
    if(index(d%message,'execution step limit exceeded')==0) error stop 'wrong specification budget error'
    checks=checks+1
    call baseline()
    ! A forged CHAR length call is checked before it can invoke impure code.
    p%expressions(p%symbols(chars)%length_expr)%symbol=g
    call verify_frontend(source,p,d)
    if(d%code==0) error stop 'length function binding mutation admitted'
    checks=checks+1
    print '(a,i0,a)','PASS: ',checks,' specification function adapter/runtime and budget checks'
contains
    subroutine baseline()
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'specification function parse baseline failed'
        end if
        f=2;g=1;arr=0;chars=0
        do j=1,p%ns
            if(p%symbols(j)%name=='a') arr=j
            if(p%symbols(j)%name=='s') chars=j
        end do
        if(arr==0.or.chars==0) error stop 'specification symbol missing'
        bound=p%symbols(arr)%upper_expr;arg=p%expressions(bound)%args(1)
        dummy=p%procedures(f)%args(1);res=p%procedures(f)%result_symbol
        assign=p%procedures(g)%first;scope=p%symbols(arr)%scope
        if(.not.valid_automatic_bound(p,bound,scope)) error stop 'specification gate baseline failed'
    end subroutine
end program
