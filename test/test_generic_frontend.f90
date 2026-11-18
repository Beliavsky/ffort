! SPDX-License-Identifier: MIT
program test_generic_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source= &
        'module overloads'//nl// &
        ' implicit none'//nl// &
        ' private'//nl// &
        ' public :: twice, change'//nl// &
        ' interface twice'//nl// &
        '  module procedure twice_int, twice_real'//nl// &
        ' end interface twice'//nl// &
        ' interface change'//nl// &
        '  module procedure change_int, change_real'//nl// &
        ' end interface'//nl// &
        'contains'//nl// &
        ' integer function twice_int(x) result(r)'//nl// &
        '  integer,intent(in)::x'//nl// &
        '  r=2*x'//nl// &
        ' end function'//nl// &
        ' real function twice_real(x) result(r)'//nl// &
        '  real,intent(in)::x'//nl// &
        '  r=2*x'//nl// &
        ' end function'//nl// &
        ' subroutine change_int(x)'//nl// &
        '  integer,intent(inout)::x'//nl// &
        '  x=3*x'//nl// &
        ' end subroutine'//nl// &
        ' subroutine change_real(x)'//nl// &
        '  real,intent(inout)::x'//nl// &
        '  x=3*x'//nl// &
        ' end subroutine'//nl// &
        'end module'//nl// &
        'program test'//nl// &
        ' use overloads, only: twice, change'//nl// &
        ' implicit none'//nl// &
        ' integer::i=4'//nl// &
        ' call change(x=i)'//nl// &
        ' print *,twice(x=2.3),twice(i)'//nl// &
        'end program'//nl
    type(program_t)::p
    type(diagnostic_t)::d
    integer::which,e,c
    do which=1,20
        call parse_subset(source,p,d)
        if(d%code/=0) then
            if(allocated(d%message)) print *,d%message
            error stop 'generic fixture parse failed'
        end if
        e=0;c=0
        do e=1,p%ne
            if(p%expressions(e)%generic_id>0) exit
        end do
        do c=1,p%nc
            if(p%code(c)%generic_id>0) exit
        end do
        select case(which)
        case(2);p%generics(1)%name='wrong'
        case(3);p%generics(1)%module_id=0
        case(4);p%generics(1)%procedure_names(1)='twice_real'
        case(5);p%generics(1)%procedures(1)=2
        case(6);p%generics(1)%nprocedures=1
        case(7);p%generics(1)%nprocedures=17
        case(8);p%generics(1)%is_public=.false.
        case(9);p%generics(1)%line=999
        case(10);p%expressions(e)%generic_id=2
        case(11);p%expressions(e)%generic_id=0
        case(12);p%expressions(e)%symbol=1
        case(13);p%code(c)%generic_id=1
        case(14);p%code(c)%generic_id=0
        case(15);p%code(c)%symbol=4
        case(16);p%generics(1)%procedures(1)=0
        case(17);p%ng=max_generics+1
        case(18);p%expressions(e)%generic_id=-1
        case(19);p%code(c)%generic_id=-1
        case(20);p%generics(1)%column=99
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            if(d%code/=0) then
                if(allocated(d%message)) print *,d%message
                error stop 'valid generic fixture rejected'
            end if
        else if(d%code==0) then
            print *,which
            error stop 'generic metadata mutation accepted'
        end if
    end do
    print *,'generic frontend: 20 cases passed'
end program
