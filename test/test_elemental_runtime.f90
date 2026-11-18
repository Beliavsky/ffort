! SPDX-License-Identifier: MIT
program test_elemental_runtime
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_runtime, only: execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer::a(2,3),i,j,empty(0,3),unused'//nl// &
        'do j=1,3'//nl//'do i=1,2'//nl//'a(i,j)=i+10*j'//nl//'end do'//nl//'end do'//nl// &
        'a(:,2:3)=f(a(:,1:2),a(1,1))'//nl// &
        'if(a(1,2)/=22.or.a(2,3)/=33) error stop 1'//nl// &
        'empty=f(empty,unused)'//nl// &
        'if(size(f(empty,unused))/=0) error stop 2'//nl// &
        'if(sum(f(a,1))/=139) error stop 3'//nl//'contains'//nl// &
        'elemental integer function f(x,y) result(r)'//nl// &
        'integer,intent(in)::x,y'//nl//'r=x+y'//nl//'end function'//nl//'end program'
    integer::which,e,j
    do which=1,6
        if(which<=4) then
            call parse_subset(source,p,d)
        else
            call parse_subset('program p'//nl//'integer::empty(0),unused'//nl// &
                'empty=f(empty,unused)'//nl//'contains'//nl// &
                'elemental integer function f(x,y) result(r)'//nl// &
                'integer,intent(in)::x,y'//nl//'r=x+y'//nl//'end function'//nl//'end program',p,d)
        end if
        if(d%code/=0) then
            print *,d%message
            error stop 'ELEMENTAL runtime baseline parse failed'
        end if
        e=0
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_user_call) then
                e=j;exit
            end if
        end do
        select case(which)
        case(2);p%procedures(1)%is_elemental=.false.
        case(3);p%procedures(1)%is_pure=.false.
        case(4,5);p%symbols(p%procedures(1)%args(1))%dummy_intent=3
        case(6);p%symbols(p%procedures(1)%result_symbol)%rank=1
        end select
        call execute_program(p,d)
        if(which==1.and.d%code/=0) then
            print *,d%message
            error stop 'ELEMENTAL runtime baseline failed'
        end if
        if(which>1.and.d%code==0) error stop 'invalid ELEMENTAL runtime IR admitted'
    end do
    print '(a)','PASS: ELEMENTAL runtime overlap, empty calls and five invalid IR checks'
end program
