! SPDX-License-Identifier: MIT
program test_elemental_mutable_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'integer::a(2),b(2)'//nl// &
        'a=2'//nl//'call change(y=b,x=a)'//nl//'contains'//nl// &
        'elemental subroutine change(x,y)'//nl//'integer,intent(in)::x'//nl// &
        'integer,intent(out)::y'//nl//'y=x+1'//nl//'end subroutine'//nl//'end program'
    character(*),parameter::impure='program p'//nl//'integer::a(2),b(2)'//nl// &
        'a=2'//nl//'b=f(a)'//nl//'call change(b)'//nl//'contains'//nl// &
        'impure elemental integer function f(x) result(r)'//nl//'integer,intent(in)::x'//nl// &
        'print *,x'//nl//'r=x+1'//nl//'end function'//nl// &
        'impure elemental subroutine change(y)'//nl//'integer,intent(inout)::y'//nl// &
        'print *,y'//nl//'y=y+1'//nl//'end subroutine'//nl//'end program'
    integer::which,c,j,e
    do which=1,7
        call parse_subset(source,p,d)
        call okay('parse')
        c=0
        do j=1,p%nc
            if(p%code(j)%op==op_call) c=j
        end do
        e=p%code(c)%items(2)
        select case(which)
        case(2);p%procedures(1)%is_elemental=.false.
        case(3);p%procedures(1)%is_pure=.false.
        case(4);p%procedures(1)%has_impure_prefix=.true.
        case(5);p%symbols(p%procedures(1)%args(1))%rank=1
        case(6);p%expressions(e)%rank=0;p%expressions(e)%extent=0
        case(7);p%code(c)%items=p%code(c)%items(2:1:-1)
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            call okay('adapter')
        else if(d%code==0) then
            print *,which
            error stop 'ELEMENTAL subroutine disagreement admitted'
        end if
    end do
    do which=1,4
        call parse_subset(impure,p,d)
        call okay('impure parse')
        select case(which)
        case(2);p%procedures(1)%has_impure_prefix=.false.
        case(3);p%procedures(2)%has_impure_prefix=.false.
        case(4);p%procedures(2)%is_pure=.true.
        end select
        call verify_frontend(impure,p,d)
        if(which==1) then
            call okay('impure adapter')
        else if(d%code==0) then
            error stop 'IMPURE ELEMENTAL disagreement admitted'
        end if
    end do
    print '(a)','PASS: ELEMENTAL subroutines and IMPURE designation adapter checks'
contains
    subroutine okay(label)
        character(*),intent(in)::label
        if(d%code==0) return
        print *,label,d%message
        error stop 'mutable ELEMENTAL frontend baseline failed'
    end subroutine
end program
