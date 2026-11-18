module m
implicit none
character(4)::storage(1)
type::box
integer::n=7
contains
procedure::write_box
generic::write(formatted)=>write_box
end type
contains
subroutine write_box(dtv,unit,iotype,v_list,iostat,iomsg)
class(box),intent(in)::dtv
integer,intent(in)::unit
character(*),intent(in)::iotype
integer,intent(in)::v_list(:)
integer,intent(out)::iostat
character(*),intent(inout)::iomsg
write(unit,'(a)',iostat=iostat,iomsg=iomsg)'DT'
end subroutine
end module
program main
use m
implicit none
type(box)::x
storage='old!'
write(storage(1),'(dt)')x
print '(a)',storage
end program
