module counters
implicit none
integer::calls=0
type::box
integer::x
contains
procedure::output
generic::write(formatted)=>output
end type
contains
subroutine output(dtv,unit,iotype,v_list,iostat,iomsg)
class(box),intent(in)::dtv
integer,intent(in)::unit
character(len=*),intent(in)::iotype
integer,intent(in)::v_list(:)
integer,intent(out)::iostat
character(len=*),intent(inout)::iomsg
character(*),parameter::child_format="(i0)"
calls=calls+1
write(unit,child_format,iostat=iostat,iomsg=iomsg) dtv%x+calls
end subroutine
end module
program main
use counters
implicit none
character(len=*),parameter::fmt='(*(dt,1x))'
type(box)::b
b=box(10)
print fmt,b,b
print '(i0)',calls
end program
