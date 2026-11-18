module counters
implicit none
type :: box
 integer :: x
contains
 procedure :: output
 generic :: write(formatted) => output
end type
contains
subroutine output(dtv,unit,iotype,v_list,iostat,iomsg)
 class(box),intent(in) :: dtv
 integer,intent(in) :: unit
 character(len=*),intent(in) :: iotype
 integer,intent(in) :: v_list(:)
 integer,intent(out) :: iostat
 character(len=*),intent(inout) :: iomsg
 write(unit,'(3i3)',iostat=iostat,iomsg=iomsg) [dtv%x,dtv%x+1,dtv%x+2]
end subroutine
end module
program p
use counters,only:box
implicit none
type(box)::b
b=box(4)
print '(a,dt,a)', '<',b,'>'
end program
