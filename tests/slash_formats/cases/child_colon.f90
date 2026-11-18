module m
implicit none
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
character(*),intent(in)::iotype
integer,intent(in)::v_list(:)
integer,intent(out)::iostat
character(*),intent(inout)::iomsg
write(unit,'(i0,:,/)',iostat=iostat,iomsg=iomsg)dtv%x
end subroutine
end module
program p
use m
implicit none
type(box)::b
b=box(4)
write(*,'(a,dt,a)')'<',b,'>'
end program
