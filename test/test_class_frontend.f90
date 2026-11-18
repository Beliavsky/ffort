! SPDX-License-Identifier: MIT
program test_class_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source= &
        'module counters'//nl// &
        ' implicit none'//nl// &
        ' private'//nl// &
        ' public :: box'//nl// &
        ' type :: box'//nl// &
        '  integer :: x'//nl// &
        ' contains'//nl// &
        '  procedure :: value'//nl// &
        '  procedure :: bump => increase'//nl// &
        '  procedure, private :: output'//nl// &
        '  generic :: write(formatted) => output'//nl// &
        ' end type'//nl// &
        'contains'//nl// &
        ' pure integer function value(this)'//nl// &
        '  class(box),intent(in) :: this'//nl// &
        '  value=this%x'//nl// &
        ' end function'//nl// &
        ' pure subroutine increase(this,n)'//nl// &
        '  class(box),intent(inout) :: this'//nl// &
        '  integer,intent(in) :: n'//nl// &
        '  this%x=this%x+n'//nl// &
        ' end subroutine'//nl// &
        ' subroutine output(dtv,unit,iotype,v_list,iostat,iomsg)'//nl// &
        '  class(box),intent(in) :: dtv'//nl// &
        '  integer,intent(in) :: unit'//nl// &
        '  character(len=*),intent(in) :: iotype'//nl// &
        '  integer,intent(in) :: v_list(:)'//nl// &
        '  integer,intent(out) :: iostat'//nl// &
        '  character(len=*),intent(inout) :: iomsg'//nl// &
        '  write(unit,''(i0)'',iostat=iostat,iomsg=iomsg) dtv%value()'//nl// &
        ' end subroutine'//nl// &
        'end module'//nl// &
        'program p'//nl// &
        ' use counters, only: box'//nl// &
        ' implicit none'//nl// &
        ' type(box) :: b,c'//nl// &
        ' b=box(4)'//nl// &
        ' c=box(9)'//nl// &
        ' call b%bump(3)'//nl// &
        ' print ''(a,dt,a,dt)'', ''b='',b,'',c='',c'//nl// &
        ' print *, b%value(), c%value()'//nl// &
        'end program'//nl
    integer::which,j,e,c,w,s
    do which=1,22
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'class fixture parse failure'
        end if
        e=0;c=0;w=0;s=0
        do j=1,p%ne
            if(p%expressions(j)%bound_type>0) e=j
        end do
        do j=1,p%nc
            if(p%code(j)%bound_type>0) c=j
            if(p%code(j)%op==op_write_defined) w=j
        end do
        do j=1,p%ns
            if(p%symbols(j)%is_class) s=j
        end do
        if(min(e,c,w,s)==0) error stop 'fixture binding metadata absent'
        select case(which)
        case(2);p%derived_types(1)%binding_names(1)='missing'
        case(3);p%derived_types(1)%binding_targets(1)='missing'
        case(4);p%derived_types(1)%binding_procedures(1)=2
        case(5);p%derived_types(1)%binding_public(2)=.false.
        case(6);p%derived_types(1)%nbindings=2
        case(7);p%derived_types(1)%write_binding='missing'
        case(8);p%derived_types(1)%write_procedure=1
        case(9);p%symbols(s)%is_class=.false.
        case(10);p%expressions(e)%bound_type=2
        case(11);p%expressions(e)%bound_binding=2
        case(12);p%expressions(e)%symbol=2
        case(13);p%code(c)%bound_binding=1
        case(14);p%code(c)%bound_type=2
        case(15);p%code(c)%items(1)=p%code(c)%items(2)
        case(16);p%code(w)%a=0
        case(17);p%code(w)%b=0
        case(18);p%code(w)%symbol=p%code(w)%a
        case(19);p%code(w)%op=op_write_internal
        case(20);p%derived_types(1)%binding_lines(1)=999
        case(21);p%derived_types(1)%write_line=999
        case(22);p%derived_types(1)%nbindings=17
        end select
        call verify_frontend(source,p,d)
        if(which==1.and.d%code/=0) then
            print *,d%message
            error stop 'valid CLASS fixture rejected'
        end if
        if(which>1.and.d%code==0) then
            print *,which
            error stop 'CLASS metadata mutation accepted'
        end if
    end do
    print '(a)', 'PASS: CLASS/type-bound/defined-I/O frontend baseline and 21 mutations'
end program
