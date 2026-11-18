! SPDX-License-Identifier: MIT
! Sections are cross-checked against FortFront, not trusted from IR caches.
program test_section_frontend
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer :: a(-2:3), b(6), i, j, k'//nl// &
        'i=-2'//nl//'j=3'//nl//'k=2'//nl//'a=1'//nl//'b=2'//nl// &
        'a(i:j:k)=b(1:5:2)+1'//nl// &
        'a(a(1):a(2):a(3))=b(b(1):b(2):b(3))'//nl// &
        'print *,a(:),a(i:),a(:j),a(::k),a(i::k),a(:j:k),a(i:j),abs(-a(:))'//nl// &
        'end program p'
    integer::which,e,target,pc,q,child
    do which=1,23
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'section adapter baseline parse failed'
        end if
        target=0;pc=0
        do q=1,p%nc
            if(p%code(q)%op/=op_assign.or.p%code(q)%c==0) cycle
            target=p%code(q)%c;pc=q
            exit
        end do
        if(target==0) error stop 'section target absent'
        e=target
        select case(which)
        case(2)
            p%expressions(e)%rank=0
        case(3)
            p%expressions(e)%extent=3_int64
        case(4)
            p%expressions(e)%symbol=2
        case(5)
            p%expressions(e)%typ=ty_real
        case(6)
            p%expressions(e)%left=0
        case(7)
            p%expressions(e)%right=0
        case(8)
            p%expressions(e)%stride=0
        case(9)
            p%expressions(e)%left=p%expressions(e)%right
        case(10)
            p%expressions(e)%right=p%expressions(e)%stride
        case(11)
            p%expressions(e)%stride=p%expressions(e)%left
        case(12)
            p%expressions(p%expressions(e)%left)%typ=ty_real
        case(13)
            p%expressions(p%expressions(e)%right)%typ=ty_logical
        case(14)
            p%expressions(p%expressions(e)%stride)%typ=ty_real
        case(15)
            p%expressions(e)%left=e
        case(16)
            p%expressions(e)%right=e
        case(17)
            p%expressions(e)%stride=e
        case(18)
            p%code(pc)%c=0
        case(19)
            p%code(pc)%b=p%expressions(e)%left
        case(20)
            p%code(pc)%c=p%code(pc)%a
        case(21)
            p%expressions(p%code(pc)%a)%extent=3_int64
        case(22)
            ! Forging a self-consistent array-valued triplet must still fail.
            child=p%expressions(e)%left
            p%expressions(child)%symbol=2
            p%expressions(child)%rank=1
            p%expressions(child)%extent=6_int64
        case(23)
            p%expressions(e)%stride=p%ne+1
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            if(d%code/=0) then
                print *,d%message
                error stop 'section adapter baseline rejected'
            end if
        else if(d%code==0) then
            print *,which
            error stop 'section adapter admitted forged IR'
        end if
    end do
    ! Add omitted operands, preserving valid scalar operand shape and type.
    do which=1,3
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'omitted triplet baseline parse failed'
        do e=1,p%ne
            if(p%expressions(e)%kind/=ex_section) cycle
            if(p%expressions(e)%left/=0.or.p%expressions(e)%right/=0.or.p%expressions(e)%stride/=0) cycle
            exit
        end do
        if(e>p%ne) error stop 'full range expression absent'
        child=p%symbols(2)%upper_expr
        select case(which)
        case(1);p%expressions(e)%left=child
        case(2);p%expressions(e)%right=child
        case(3);p%expressions(e)%stride=child
        end select
        call verify_frontend(source,p,d)
        if(d%code==0) error stop 'unexpected triplet operand admitted'
    end do
    ! Missing FortFront occurrence flags in triplets do not relax bindings,
    ! scalar INTEGER subscripts, or the exact operand expression tree.
    do which=1,3
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'nested triplet baseline parse failed'
        do e=1,p%ne
            if(p%expressions(e)%kind==ex_element) exit
        end do
        if(e>p%ne) error stop 'nested triplet element absent'
        select case(which)
        case(1);p%expressions(e)%symbol=2
        case(2);p%expressions(p%expressions(e)%left)%typ=ty_real
        case(3);p%expressions(p%expressions(e)%left)%value%i=6_int64
        end select
        call verify_frontend(source,p,d)
        if(d%code==0) error stop 'forged nested triplet element admitted'
    end do
    print '(a)','PASS: section adapter baseline and 28 deliberate AST/IR disagreements'
end program
