module boxes
  implicit none
  private
  public :: box, twice
  type :: box
    integer :: x
  contains
    procedure :: text
    procedure, private :: output
    generic :: write(formatted) => output
  end type
  interface twice
    module procedure twice_box, twice_integer
  end interface twice
contains
  function twice_box(x) result(y)
    type(box), intent(in) :: x
    type(box) :: y
    y=box(2*x%x)
  end function
  integer function twice_integer(x) result(y)
    integer, intent(in) :: x
    y=2*x
  end function
  character(2) function text(this) result(s)
    class(box), intent(in) :: this
    write(s,'(i2.2)') this%x
  end function
  subroutine output(dtv,unit,iotype,v_list,iostat,iomsg)
    class(box),intent(in) :: dtv
    integer,intent(in) :: unit
    character(*),intent(in) :: iotype
    integer,intent(in) :: v_list(:)
    integer,intent(out) :: iostat
    character(*),intent(inout) :: iomsg
    write(unit,'(a)',iostat=iostat,iomsg=iomsg) dtv%text()
  end subroutine
end module
program main
  use boxes, only: box,twice
  implicit none
  type(box)::b,c
  character(2)::names(2)
  b=box(3)
  c=twice(b)
  names=[b%text(),c%text()]
  print '(a,a,a,dt,i0)','>'//names(1),'>'//names(2),':',c,twice(7)
end program
