module m
implicit none
type::dt
character(65536)::s='cat'
contains
procedure::output
generic::write(formatted)=>output
end type
contains
subroutine output(dtv,unit,iotype,v_list,iostat,iomsg)
class(dt),intent(in)::dtv
integer,intent(in)::unit
character(len=*),intent(in)::iotype
integer,intent(in)::v_list(:)
integer,intent(out)::iostat
character(len=*),intent(inout)::iomsg
write(unit,'(a)',iostat=iostat,iomsg=iomsg) trim(dtv%s)
end subroutine
end module
use m
implicit none
type(dt)::x
print '(dt)',x
end
