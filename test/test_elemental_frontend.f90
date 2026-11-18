! SPDX-License-Identifier: MIT
program test_elemental_frontend
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer::a(2,3),b(2,3)'//nl//'a=2'//nl//'b=f(y=3,x=a)'//nl// &
        'print *,f(x=b,y=1)'//nl//'contains'//nl// &
        'pure elemental integer function f(x,y) result(r)'//nl// &
        'integer,intent(in)::x,y'//nl//'r=x+y'//nl//'end function'//nl//'end program'
    integer::which,e,s
    do which=1,10
        call parse_subset(source,p,d)
        call require_ok('baseline parse')
        if(.not.p%procedures(1)%is_elemental.or..not.p%procedures(1)%is_pure) error stop 'ELEMENTAL metadata absent'
        e=0
        do s=1,p%ne
            if(p%expressions(s)%kind==ex_user_call) then
                e=s;exit
            end if
        end do
        if(e==0.or.p%expressions(e)%rank/=2) error stop 'array call rank absent'
        select case(which)
        case(2);p%procedures(1)%is_elemental=.false.
        case(3);p%procedures(1)%is_pure=.false.
        case(4);p%procedures(1)%has_pure_prefix=.false.
        case(5);p%expressions(e)%rank=0;p%expressions(e)%extent=0
        case(6);p%expressions(e)%dims=[3_int64,2_int64,1_int64]
        case(7);p%expressions(e)%typ=ty_real
        case(8);p%symbols(p%procedures(1)%args(1))%rank=1
        case(9);p%symbols(p%procedures(1)%args(2))%dummy_intent=3
        case(10);p%expressions(e)%args=p%expressions(e)%args(2:1:-1)
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            call require_ok('baseline verification')
        else if(d%code==0) then
            print *,which
            error stop 'ELEMENTAL adapter disagreement admitted'
        end if
    end do
    call rejected('elemental elemental integer function f(x) result(r)', &
        'integer,intent(in)::x','Duplicate ELEMENTAL')
    call rejected('elemental integer function f(x) result(r)', &
        'integer,intent(in)::x(:)','must be scalar')
    call rejected('pure impure elemental integer function f(x) result(r)', &
        'integer,intent(in)::x','IMPURE')
    print '(a)','PASS: ELEMENTAL baseline, nine adapter disagreements and three declaration rejections'
contains
    subroutine rejected(header,declaration,wanted)
        character(*),intent(in)::header,declaration,wanted
        call parse_subset('program p'//nl//'contains'//nl//header//nl//declaration//nl// &
            'r=1'//nl//'end function'//nl//'end program',p,d)
        if(d%code==0) error stop 'invalid ELEMENTAL declaration admitted'
        if(index(d%message,wanted)==0) then
            print *,d%message
            error stop 'wrong ELEMENTAL diagnostic'
        end if
    end subroutine
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code==0) return
        print *,label,d%message
        error stop 'ELEMENTAL frontend test failed'
    end subroutine
end program
