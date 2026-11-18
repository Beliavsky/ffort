! SPDX-License-Identifier: MIT
program test_derived_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source= &
        'module dates'//nl// &
        ' implicit none'//nl// &
        ' private'//nl// &
        ' type, public :: date_t'//nl// &
        '  integer :: year,month'//nl// &
        ' end type'//nl// &
        ' public :: operator(+), eq'//nl// &
        ' interface operator(+)'//nl// &
        '  module procedure add'//nl// &
        ' end interface'//nl// &
        'contains'//nl// &
        ' function add(d,n) result(r)'//nl// &
        '  type(date_t),intent(in) :: d'//nl// &
        '  integer,intent(in):: n'//nl// &
        '  type(date_t) :: r'//nl// &
        '  r=d'//nl// &
        '  r%month=d%month+n'//nl// &
        ' end function'//nl// &
        ' logical function eq(a,b)'//nl// &
        '  type(date_t),intent(in) :: a,b'//nl// &
        '  eq=a%year==b%year.and.a%month==b%month'//nl// &
        ' end function'//nl// &
        'end module'//nl// &
        'program test'//nl// &
        ' use dates'//nl// &
        ' implicit none'//nl// &
        ' type(date_t) :: d'//nl// &
        ' d=date_t(2026,1)'//nl// &
        ' d=d+2'//nl// &
        ' if(.not.eq(d,date_t(2026,3))) &'//nl// &
        ' stop ''bad'''//nl// &
        ' print *,d%year,d%month'//nl// &
        'end program'//nl
    character(:),allocatable::active_source
    integer::which,e,c,mode,at
    do mode=1,2
    active_source=source
    if(mode==2) then
        at=index(source,' use dates')
        active_source=source(:at-1)//' use dates, only: date_t, eq, operator(+)'// &
            source(at+len(' use dates'):)
    end if
    do which=1,18
        if(mode==1.and.which>16) cycle
        call parse_subset(active_source,p,d)
        if(d%code/=0) then
            if(allocated(d%message)) print *,d%message
            error stop 'derived frontend fixture parse failed'
        end if
        select case(which)
        case(2);p%derived_types(1)%name='wrong'
        case(3);p%derived_types(1)%component_names(1)='wrong'
        case(4);p%derived_types(1)%component_types(1)=ty_real
        case(5);p%derived_types(1)%is_public=.false.
        case(6);p%derived_types(1)%ncomponents=1
        case(7);p%operators(1)%procedure_names(1)='eq'
        case(8);p%operators(1)%procedures(1)=2
        case(9);p%operators(1)%is_public=.false.
        case(10);p%operators(1)%nprocedures=0
        case(11)
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_component) cycle
                p%expressions(e)%symbol=3
                exit
            end do
        case(12)
            do c=1,p%nc
                if(p%code(c)%component==0) cycle
                p%code(c)%component=1
                exit
            end do
        case(13)
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_user_call.or.len_trim(p%expressions(e)%op)==0) cycle
                p%expressions(e)%op='-'
                exit
            end do
        case(14)
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_record) cycle
                p%expressions(e)%typ=ty_derived_base+2
                exit
            end do
        case(15);p%procedures(2)%result_symbol=p%procedures(2)%args(1)
        case(16)
            do c=1,p%nc
                if(p%code(c)%op/=op_stop) cycle
                p%code(c)%line=p%code(c)%line-1
                exit
            end do
        case(17);p%only_names(3,1)='operator(-)'
        case(18);p%use_only(1)=.false.
        end select
        call verify_frontend(active_source,p,d)
        if((d%code==0).neqv.(which==1)) then
            print *,which
            if(allocated(d%message)) print *,d%message
            error stop 'derived frontend mutation regression'
        end if
    end do
    end do
    print '(a)','PASS: 34 derived frontend identity, structure and USE ONLY checks'
end program
