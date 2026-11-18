! SPDX-License-Identifier: MIT
! Independent adapter shape derivation must reject forged IR caches.
program test_array_expression_frontend
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer :: a(3), b(-1:1), c(2), z(0), i'//nl// &
        'logical :: flags(3)'//nl//'a=1'//nl//'b=+a'//nl// &
        'a=b+2'//nl//'a=max(a,abs(-b),3)'//nl//'flags=a>0'//nl// &
        'i=a(1)'//nl//'z=7'//nl//'print *,a,b+1,flags,z'//nl//'end program p'
    character(:),allocatable::valid,invalid
    integer::which,j,e,kind
    do which=1,16
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'array expression baseline parse failed'
        end if
        select case(which)
        case(2:7)
            kind=which-1
            do e=1,p%ne
                if(p%expressions(e)%kind/=kind) cycle
                p%expressions(e)%rank=1-p%expressions(e)%rank
                exit
            end do
            if(e>p%ne) error stop 'missing expression kind in rank mutation'
        case(8:13)
            kind=which-7
            do e=1,p%ne
                if(p%expressions(e)%kind/=kind) cycle
                p%expressions(e)%extent=p%expressions(e)%extent+1_int64
                exit
            end do
            if(e>p%ne) error stop 'missing expression kind in extent mutation'
        case(14)
            ! Even with a self-consistent forged parent cache, child shape wins.
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_binary) cycle
                p%expressions(e)%rank=0;p%expressions(e)%extent=0_int64
                exit
            end do
        case(15)
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_unary) cycle
                p%expressions(e)%left=e
                exit
            end do
        case(16)
            do j=1,p%nc
                if(p%code(j)%op/=op_assign.or.p%code(j)%symbol/=1) cycle
                ! Scalar broadcast target is changed to an element without AST support.
                p%code(j)%b=p%symbols(1)%upper_expr
                exit
            end do
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            if(d%code/=0) then
                print *,d%message
                error stop 'array expression baseline rejected'
            end if
        else if(d%code==0) then
            print *,which
            error stop 'array expression adapter admitted forged shape'
        end if
    end do
    ! Start from a parsed scalar assignment, then give both AST and IR the same
    ! array RHS. Only the independently checked assignment context rejects it.
    call parse_subset('integer :: a(3), i'//nl//'i=a(1)'//nl//'end',p,d)
    if(d%code/=0) error stop 'scalar target baseline parse failed'
    e=p%code(1)%a
    p%expressions(e)%kind=ex_variable;p%expressions(e)%left=0
    p%expressions(e)%rank=1;p%expressions(e)%extent=3_int64
    call verify_frontend('integer :: a(3), i'//nl//'i=a'//nl//'end',p,d)
    if(d%code==0) error stop 'array RHS admitted for scalar target'
    ! Likewise, preserve the expression AST and caches but disagree with the
    ! target extent. Declaration and variable caches are mutually consistent.
    call parse_subset('integer :: a(3), b(3)'//nl//'a=b'//nl//'end',p,d)
    if(d%code/=0) error stop 'conformable target baseline parse failed'
    p%symbols(1)%upper_bound=2_int64
    p%expressions(p%symbols(1)%upper_expr)%value%i=2_int64
    call verify_frontend('integer :: a(2), b(3)'//nl//'a=b'//nl//'end',p,d)
    if(d%code==0) error stop 'nonconformable assignment target admitted'
    do which=1,3
        select case(which)
        case(1)
            valid='logical :: f(3)'//nl//'if(f(1)) then'//nl//'print *,1'//nl//'end if'//nl//'end'
            invalid='logical :: f(3)'//nl//'if(f) then'//nl//'print *,1'//nl//'end if'//nl//'end'
        case(2)
            valid='integer :: a(3),i'//nl//'do i=1,a(1)'//nl//'print *,i'//nl//'end do'//nl//'end'
            invalid='integer :: a(3),i'//nl//'do i=1,a'//nl//'print *,i'//nl//'end do'//nl//'end'
        case(3)
            valid='integer :: a(3),b(3),i'//nl//'i=a(b(1))'//nl//'end'
            invalid='integer :: a(3),b(3),i'//nl//'i=a(b)'//nl//'end'
        end select
        call parse_subset(valid,p,d)
        if(d%code/=0) error stop 'scalar context baseline parse failed'
        do e=1,p%ne
            if(p%expressions(e)%kind/=ex_element) cycle
            p%expressions(e)%kind=ex_variable;p%expressions(e)%left=0
            p%expressions(e)%rank=1;p%expressions(e)%extent=3_int64
            exit
        end do
        call verify_frontend(invalid,p,d)
        if(d%code==0) error stop 'array expression admitted in scalar-only context'
    end do
    print '(a)','PASS: array expression baseline and 20 independent shape disagreements' 
end program
