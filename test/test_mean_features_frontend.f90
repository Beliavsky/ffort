! SPDX-License-Identifier: MIT
program test_mean_features_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'real :: a(3)=[1.0,2.0,3.0]'//nl//'real(8) :: b(2,2)=0.0_8'//nl// &
        'real(kind=kind(1d0)) :: g,h'//nl// &
        'real(kind=kind(1d0))::v(2)'//nl// &
        'real :: x'//nl//'integer,parameter :: k=kind(x)'//nl// &
        'call random_number(harvest=a)'//nl//'call random_number(b(:,1))'//nl// &
        'call random_number(x)'//nl//'print *,kind(x=a),[x,a],(/1,2/)'//nl// &
        'print *,[1,[2,3],(/4,5/)],(/1,(/2,3/),4/)'//nl//'end program'
    character(:),allocatable::changed
    integer::which,e,c,j,q
    do which=1,24
        call parse_subset(source,p,d)
        call require_ok('baseline parse')
        e=find_expression(ex_constructor);c=find_instruction(op_random_number)
        changed=source
        select case(which)
        case(2);p%expressions(e)%rank=0
        case(3);p%expressions(e)%extent=2
        case(4);p%expressions(e)%typ=ty_integer
        case(5);p%expressions(e)%args(1)=0
        case(6);p%expressions(e)%args(1)=e
        case(7);p%expressions(e)%args=[integer::]
        case(8);deallocate(p%expressions(e)%args)
        case(9);p%expressions(e)%args=p%expressions(e)%args(:2)
        case(10);p%expressions(e)%real_kind=8
        case(11);p%code(c)%a=0
        case(12);p%code(c)%symbol=0
        case(13);p%expressions(p%code(c)%a)%parenthesized=.true.
        case(14);p%symbols(p%code(c)%symbol)%is_parameter=.true.
        case(15);p%symbols(p%code(c)%symbol)%dummy_intent=1
        case(16);changed=replace(source,'harvest=a','wrong=a')
        case(17);changed=replace(source,'random_number(x)','random_number(x,a)')
        case(18);changed=replace(source,'[1.0,2.0,3.0]','[real :: 1.0,2.0,3.0]')
        case(19:23)
            e=find_expression(ex_call)
            select case(which)
            case(19);p%expressions(e)%rank=1
            case(20);p%expressions(e)%typ=ty_real
            case(21);p%expressions(e)%args=[p%expressions(e)%args,p%expressions(e)%args]
            case(22);p%expressions(e)%args(1)=0
            case(23);p%expressions(e)%args(1)=e
            end select
        case(24);changed=replace(source,'kind(x=a)','kind(wrong=a)')
        end select
        call verify_frontend(changed,p,d)
        if(which==1) then
            call require_ok('baseline verification')
        else if(d%code==0) then
            print *,which
            error stop 'forged mean feature IR admitted'
        end if
    end do
    print '(a)','PASS: mean-feature baseline and 23 adapter disagreements'
contains
    integer function find_expression(kind) result(e)
        integer,intent(in)::kind
        do e=1,p%ne
            if(p%expressions(e)%kind==kind) return
        end do
        error stop 'test expression absent'
    end function
    integer function find_instruction(op) result(c)
        integer,intent(in)::op
        do c=1,p%nc
            if(p%code(c)%op==op) return
        end do
        error stop 'test instruction absent'
    end function
    function replace(text,old,new) result(out)
        character(*),intent(in)::text,old,new
        character(:),allocatable::out
        integer::i
        i=index(text,old)
        if(i==0) error stop 'test replacement absent'
        out=text(:i-1)//new//text(i+len(old):)
    end function
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'unexpected failure'
        end if
    end subroutine
end program
