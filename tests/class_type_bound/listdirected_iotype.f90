module counters
 implicit none
 private
 public :: box
 type :: box
  integer :: x
 contains
  procedure :: value
  procedure :: bump => increase
  procedure, private :: output
  generic :: write(formatted) => output
 end type
contains
 pure integer function value(this)
  class(box),intent(in) :: this
  value=this%x
 end function
 pure subroutine increase(this,n)
  class(box),intent(inout) :: this
  integer,intent(in) :: n
  this%x=this%x+n
 end subroutine
 subroutine output(dtv,unit,iotype,v_list,iostat,iomsg)
  class(box),intent(in) :: dtv
  integer,intent(in) :: unit
  character(len=*),intent(in) :: iotype
  integer,intent(in) :: v_list(:)
  integer,intent(out) :: iostat
  character(len=*),intent(inout) :: iomsg
  if(iotype /= 'LISTDIRECTED') error stop 'iotype mismatch'
  write(unit,'(i0)',iostat=iostat,iomsg=iomsg) dtv%value()
 end subroutine
end module
program p
 use counters, only: box
 implicit none
 type(box) :: b,c
 b=box(4)
 c=box(9)
 call b%bump(3)
 print *, b
 print *, b%value(), c%value()
end program
