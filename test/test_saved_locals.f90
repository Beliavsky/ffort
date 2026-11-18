! SPDX-License-Identifier: MIT
program test_saved_locals
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
        'subroutine bump(v)'//nl//'integer,intent(out)::v'//nl//'integer,save::n=0'//nl// &
        'n=n+1'//nl//'v=n'//nl//'end subroutine'//nl// &
        'recursive subroutine recurse(k,v)'//nl//'integer,intent(in)::k'//nl//'integer,intent(out)::v'//nl// &
        'integer::n=0'//nl//'n=n+1'//nl//'if(k>0) call recurse(k-1,v)'//nl//'v=n'//nl//'end subroutine'//nl// &
        'subroutine letters(v)'//nl//'character(len=3),intent(out)::v'//nl// &
        "character(len=3),save::word='ab'"//nl//"word=word(2:)//'x'"//nl//'v=word'//nl//'end subroutine'//nl// &
        'end module'//nl//'program p'//nl//'use m'//nl//'implicit none'//nl//'integer::v'//nl// &
        'character(len=3)::s'//nl//'call bump(v)'//nl//'if(v/=1) error stop 1'//nl// &
        'call bump(v)'//nl//'if(v/=2) error stop 2'//nl//'call recurse(2,v)'//nl// &
        'if(v/=3) error stop 3'//nl//'call recurse(0,v)'//nl//'if(v/=4) error stop 4'//nl// &
        'call letters(s)'//nl//"if(s/='b x') error stop 5"//nl// &
        'call letters(s)'//nl//"if(s/=' xx') error stop 6"//nl//'end program'
    integer::stage,which,j,saved,char_saved,owner,arg,checks
    integer(int64)::budget
    checks=0
    do stage=1,2
        do which=1,29
            call baseline()
            select case(which)
            case(2);p%symbols(saved)%is_saved=.false.
            case(3);p%symbols(saved)%scope=0
            case(4);p%procedures(owner)%is_pure=.true.
            case(5);p%procedures(owner)%is_simple=.true.
            case(6);p%symbols(saved)%rank=1
            case(7);p%symbols(saved)%is_dummy=.true.
            case(8);p%symbols(saved)%is_parameter=.true.
            case(9);p%symbols(saved)%is_optional=.true.
            case(10);p%symbols(saved)%dummy_intent=1
            case(11);p%symbols(saved)%is_allocatable=.true.
            case(12);p%symbols(saved)%is_pointer=.true.
            case(13);p%symbols(saved)%is_target=.true.
            case(14);p%symbols(saved)%is_automatic=.true.
            case(15);p%symbols(saved)%initializer_expr=0
            case(16);p%symbols(saved)%parameter_ready=.false.
            case(17);p%symbols(saved)%constant_value%i=1_int64
            case(18);p%symbols(saved)%constant_value%tag=ty_real
            case(19);p%symbols(saved)%constant_value%real_kind=8
            case(20);p%symbols(saved)%real_kind=16
            case(21);p%symbols(saved)%lower_expr=p%symbols(saved)%initializer_expr
            case(22);p%symbols(saved)%upper_bound=2_int64
            case(23);p%procedures(owner)%result_symbol=saved
            case(24);p%symbols(char_saved)%character_len=4
            case(25);p%symbols(char_saved)%constant_value%s='abc'
            case(26);p%symbols(char_saved)%constant_value%s='ab'
            case(27);p%symbols(saved)%initializer_expr=arg
            case(28);p%symbols(char_saved)%length_expr=arg
            case(29);p%symbols(saved)%is_class=.true.
            end select
            if(stage==1) then
                call verify_frontend(source,p,d)
            else
                call execute_program(p,d,max_steps=5000_int64)
            end if
            checks=checks+1
            if((which==1.and.d%code/=0).or.(which/=1.and.d%code==0)) then
                print *,stage,which,d%code
                if(allocated(d%message)) print *,d%message
                error stop 'SAVE mutation expectation failed'
            end if
            if(stage==2.and.which/=1.and.d%code/=2) error stop 'wrong SAVE runtime error class'
        end do
    end do
    ! The same immutable program executes twice with fresh SAVE state, after
    ! both successful and budget-failed roots. No process-wide compiler SAVE.
    call baseline()
    do which=1,3
        d=diagnostic_t()
        call execute_program(p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'SAVE state leaked between root executions'
        end if
        if(p%symbols(saved)%constant_value%i/=0_int64) error stop 'SAVE mutated IR initializer'
        checks=checks+1
    end do
    budget=8_int64;d=diagnostic_t()
    call execute_program(p,d,budget_remaining=budget)
    if(d%code/=2.or.budget/=0_int64) error stop 'SAVE initialization did not share budget'
    checks=checks+1
    d=diagnostic_t();call execute_program(p,d)
    if(d%code/=0) error stop 'SAVE state leaked after budget failure'
    checks=checks+1
    print '(a,i0,a)','PASS: ',checks,' SAVE adapter/runtime/cache/reset checks'
contains
    subroutine baseline()
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'SAVE baseline parse failed'
        end if
        saved=0;char_saved=0;arg=0
        do j=1,p%ns
            if(p%symbols(j)%name=='n'.and.p%symbols(j)%scope==1) saved=j
            if(p%symbols(j)%name=='word') char_saved=j
        end do
        owner=p%symbols(saved)%scope
        do j=1,p%ne
            if(p%expressions(j)%kind/=ex_variable) cycle
            if(p%expressions(j)%symbol==p%procedures(2)%args(1)) arg=j
        end do
        if(saved==0.or.char_saved==0.or.arg==0) error stop 'SAVE baseline metadata missing'
    end subroutine
end program
