! SPDX-License-Identifier: MIT
! Array adapter checks are independent of CLI output/runtime semantics.
program test_array_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer :: a(3), b(-2:2), i'//nl//'real :: r(0:1)'//nl// &
        'logical :: flag(2)'//nl//'i=1'//nl//'a(i)=3'//nl// &
        'b(-2)=a(i)'//nl//'r(0)=real(b(-2))'//nl//'flag(1)=r(0)>1.0'//nl// &
        'print *,a(i),b(-2),r(0),flag(1)'//nl//'end program p'
    integer::which,i,pc
    do which=1,12
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'array adapter baseline parse failed'
        end if
        select case(which)
        case(2)
            p%expressions(p%symbols(1)%upper_expr)%value%i=4
        case(3)
            p%symbols(2)%lower_expr=0
        case(4)
            p%symbols(1)%rank=0
        case(5)
            do i=1,p%nc
                if(p%code(i)%op/=op_assign.or.p%code(i)%symbol/=1) cycle
                p%code(i)%b=p%symbols(1)%upper_expr
                exit
            end do
        case(6)
            do i=1,p%ne
                if(p%expressions(i)%kind/=ex_element) cycle
                p%expressions(i)%symbol=2
                exit
            end do
        case(7)
            do pc=1,p%nc
                if(p%code(pc)%op/=op_assign.or.p%code(pc)%symbol/=1) cycle
                p%code(pc)%b=0
                exit
            end do
        case(8)
            p%symbols(1)%upper_bound=4
        case(9)
            p%symbols(2)%lower_bound=-1
        case(10)
            p%symbols(1)%lower_bound=0
        case(11)
            p%expressions(p%symbols(1)%upper_expr)%typ=ty_real
        case(12)
            do pc=1,p%nc
                if(p%code(pc)%op/=op_assign.or.p%code(pc)%symbol/=1) cycle
                p%expressions(p%code(pc)%b)%typ=ty_real
                exit
            end do
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            if(d%code/=0) then
                print *,d%message
                error stop 'array adapter baseline rejected'
            end if
        else
            if(d%code==0) then
                print *,which
                error stop 'array adapter admitted mismatched IR'
            end if
        end if
    end do
    call parse_subset('program p'//nl//'implicit none'//nl// &
        'INTEGER :: Values(-1:0)'//nl//'vALues(-1)=7'//nl//'VALUES(0)=9'//nl// &
        'PRINT *,values(-1),VaLuEs(0)'//nl//'end program p',p,d)
    if(d%code/=0) error stop 'mixed-case array source parse failed'
    call verify_frontend('program p'//nl//'implicit none'//nl// &
        'INTEGER :: Values(-1:0)'//nl//'vALues(-1)=7'//nl//'VALUES(0)=9'//nl// &
        'PRINT *,values(-1),VaLuEs(0)'//nl//'end program p',p,d)
    if(d%code/=0) then
        print *,d%message
        error stop 'mixed-case array names did not resolve'
    end if
    print '(a)','PASS: 2 array adapter baselines and 11 deliberate AST/IR disagreements'
end program
