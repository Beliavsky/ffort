! SPDX-License-Identifier: MIT
program test_release_metadata
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'type::box'//nl//'integer::x'//nl// &
        'contains'//nl//'procedure::value'//nl//'end type'//nl// &
        'interface generic_zero'//nl//'module procedure zero'//nl//'end interface'//nl// &
        'contains'//nl//'integer function value(this)'//nl//'class(box),intent(in)::this'//nl// &
        'value=this%x'//nl//'end function'//nl// &
        'integer function zero()'//nl//'zero=0'//nl//'end function'//nl// &
        'subroutine visit()'//nl//'end subroutine'//nl//'end module'//nl// &
        'program main'//nl//'use m'//nl//'implicit none'//nl// &
        'print *,zero(),generic_zero()'//nl//'call visit()'//nl//'end'
    integer::which,j,ordinary,generic,literal,call_pc,print_pc
    do which=0,9
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'integration metadata baseline parse failed'
        ordinary=0;generic=0;literal=0;call_pc=0;print_pc=0
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_literal) literal=j
            if(p%expressions(j)%kind/=ex_user_call) cycle
            if(p%expressions(j)%generic_id==0) ordinary=j
            if(p%expressions(j)%generic_id>0) generic=j
        end do
        do j=1,p%nc
            if(p%code(j)%op==op_call) call_pc=j
            if(p%code(j)%op==op_print) print_pc=j
        end do
        if(min(ordinary,generic,literal,call_pc,print_pc)==0) error stop 'integration metadata fixture missing'
        select case(which)
        case(1)
            p%expressions(ordinary)%bound_type=1;p%expressions(ordinary)%bound_binding=1
        case(2)
            p%expressions(generic)%bound_binding=1
        case(3)
            p%expressions(literal)%bound_type=1;p%expressions(literal)%bound_binding=1
        case(4)
            p%code(call_pc)%bound_type=1;p%code(call_pc)%bound_binding=1
        case(5)
            p%expressions(ordinary)%bound_type=1
        case(6)
            p%code(call_pc)%bound_binding=1
        case(7)
            p%code(print_pc)%bound_type=1;p%code(print_pc)%bound_binding=1
        case(8)
            p%expressions(ordinary)%bound_type=1;p%expressions(ordinary)%bound_binding=1
            deallocate(p%expressions(ordinary)%args)
        case(9)
            p%code(call_pc)%bound_type=1;p%code(call_pc)%bound_binding=1
            deallocate(p%code(call_pc)%items)
        end select
        call verify_frontend(source,p,d)
        if(which==0) then
            if(d%code/=0) then
                print *,d%message
                error stop 'integration metadata baseline verification failed'
            end if
        else
            if(d%code==0) error stop 'forged bound metadata admitted'
        end if
    end do
    print '(a)','PASS: combined generic/bound metadata and nine safe corruption rejections'
end program
