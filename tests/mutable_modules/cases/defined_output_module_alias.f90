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
calls=calls+1
write(unit,'(i0)',iostat=iostat,iomsg=iomsg) dtv%x+calls
end subroutine
subroutine change(x)
integer,intent(inout)::x
type(box)::b
b=box(10)
print '(dt)',b
x=x+1
end subroutine
end module
program main
use counters
implicit none
type(box)::b
call change(calls)
end program
