! SPDX-License-Identifier: MIT
program test_main_save
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'recursive subroutine bump(a,n)'//nl//'integer,intent(inout)::a(:,:)'//nl// &
        'integer,intent(in)::n'//nl//'integer,save::tick=0'//nl//'tick=tick+1'//nl//'a=a+tick'//nl// &
        'if(n>0) call bump(a,n-1)'//nl//'end subroutine'//nl//'end module'//nl// &
        'program p'//nl//'use m'//nl//'implicit none'//nl// &
        'integer,save::a(-1:0,2:3)=reshape([1,2,3,4],[2,2]),v=7'//nl// &
        "character(len=3),save::words(2)='ab'"//nl// &
        'if(any(a/=reshape([1,2,3,4],[2,2])) .or. v/=7) error stop 1'//nl// &
        "if(any(words/='ab ')) error stop 2"//nl// &
        'call bump(a,2)'//nl//'call bump(a,0)'//nl//'v=v+1'//nl//"words='xy'"//nl// &
        'if(any(a/=reshape([11,12,13,14],[2,2])) .or. v/=8) error stop 3'//nl// &
        "if(any(words/='xy ')) error stop 4"//nl//'end program'
    integer::which,s,word_s,j,pc,expr,checks,tick_s
    integer(int64)::budget
    checks=0
    do which=1,30
        call baseline()
        select case(which)
        case(2);p%symbols(s)%is_saved=.true.
        case(3);p%symbols(s)%initializer_expr=0
        case(4);p%symbols(s)%initializer_expr=prog_expr()
        case(5);p%symbols(s)%parameter_ready=.true.
        case(6);allocate(p%symbols(s)%constant_values(4))
        case(7);p%symbols(s)%is_parameter=.true.
        case(8);p%symbols(s)%is_dummy=.true.
        case(9);p%symbols(s)%is_optional=.true.
        case(10);p%symbols(s)%dummy_intent=1
        case(11);p%symbols(s)%is_allocatable=.true.
        case(12);p%symbols(s)%is_pointer=.true.
        case(13);p%symbols(s)%is_target=.true.
        case(14);p%symbols(s)%is_class=.true.
        case(15);p%symbols(s)%is_automatic=.true.
        case(16);p%symbols(s)%assumed_shape=.true.
        case(17);p%symbols(s)%deferred_character=.true.
        case(18);p%symbols(s)%scope=1
        case(19);p%symbols(s)%rank=4
        case(20);p%symbols(s)%typ=ty_real
        case(21);p%symbols(s)%real_kind=8
        case(22);p%symbols(s)%upper_bound=2_int64
        case(23);p%symbols(s)%lower_bound=0_int64
        case(24);p%symbols(s)%upper_bound2=4_int64
        case(25);p%symbols(word_s)%character_len=4
        case(26);p%code(pc)%a=prog_expr()
        case(27);p%expressions(expr)%real_kind=8
        case(28);p%expressions(expr)%rank=0
        case(29);p%code(pc)%op=op_print
        case(30);p%symbols(s)%initializer_expr=p%ne+1
        end select
        call verify_frontend(source,p,d)
        checks=checks+1
        if((which==1.and.d%code/=0).or.(which/=1.and.d%code==0)) then
            print *,which,d%code
            if(allocated(d%message))print *,d%message
            error stop 'main SAVE adapter mutation expectation failed'
        end if
    end do
    ! A false procedure-SAVE flag or owner must not select persistent storage.
    do which=1,3
        call baseline()
        select case(which)
        case(2);p%symbols(s)%is_saved=.true.
        case(3);p%symbols(s)%scope=1
        end select
        call execute_program(p,d,max_steps=2000_int64)
        checks=checks+1
        if((which==1.and.d%code/=0).or.(which/=1.and.d%code/=2)) then
            if(allocated(d%message))print *,d%message
            error stop 'main SAVE runtime ownership guard failed'
        end if
    end do
    ! Re-execute one immutable IR, including after a failed root. All root data
    ! and the existing procedure-SAVE store must start from their initial values.
    call baseline()
    do which=1,3
        d=diagnostic_t();call execute_program(p,d,max_steps=2000_int64)
        if(d%code/=0) then
            if(allocated(d%message))print *,d%message
            error stop 'main SAVE state leaked between roots'
        end if
        if(p%symbols(s)%is_saved.or.p%symbols(s)%parameter_ready.or. &
           allocated(p%symbols(s)%constant_values)) error stop 'main SAVE storage changed IR'
        if(p%symbols(tick_s)%constant_value%i/=0_int64) error stop 'procedure SAVE changed initializer'
        if(p%symbols(s)%initializer_expr/=expr)error stop 'main SAVE changed initializer'
        checks=checks+1
    end do
    budget=3_int64;d=diagnostic_t()
    call execute_program(p,d,budget_remaining=budget)
    if(d%code/=2.or.budget/=0_int64)error stop 'main SAVE initialization bypassed execution budget'
    checks=checks+1
    d=diagnostic_t();call execute_program(p,d,max_steps=2000_int64)
    if(d%code/=0)error stop 'main SAVE state leaked after failed root'
    checks=checks+1
    print '(a,i0,a)','PASS: ',checks,' main SAVE source/IR/storage/reset checks'
contains
    integer function prog_expr() result(e)
        e=0
        do j=1,p%ne
            if(p%expressions(j)%kind/=ex_literal)cycle
            if(p%expressions(j)%typ/=ty_integer.or.p%expressions(j)%scope/=0)cycle
            e=j;return
        end do
        error stop 'main SAVE literal absent'
    end function
    subroutine baseline()
        call parse_subset(source,p,d)
        if(d%code/=0)then
            print *,d%message
            error stop 'main SAVE baseline parse failed'
        end if
        s=0;word_s=0;tick_s=0
        do j=1,p%ns
            if(p%symbols(j)%name=='tick')tick_s=j
            if(p%symbols(j)%scope/=0)cycle
            if(p%symbols(j)%name=='a')s=j
            if(p%symbols(j)%name=='words')word_s=j
        end do
        if(s==0.or.word_s==0.or.tick_s==0)error stop 'main SAVE symbol missing'
        if(p%symbols(s)%is_saved.or.p%symbols(s)%parameter_ready)error stop 'main SAVE misclassified'
        expr=p%symbols(s)%initializer_expr;pc=0
        do j=1,p%nc
            if(p%code(j)%op==op_assign.and.p%code(j)%symbol==s.and.p%code(j)%a==expr)pc=j
        end do
        if(pc==0)error stop 'main SAVE initializer instruction absent'
    end subroutine
end program
