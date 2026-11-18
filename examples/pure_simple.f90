module pure_simple_math
  implicit none
  integer, parameter :: bias=3
contains
  simple integer function shifted(x) result(r)
    integer, intent(in) :: x
    r=x+bias
  end function
  integer pure function total(x) result(r)
    integer, intent(in) :: x(:)
    r=sum(x)+shifted(2)
  end function
  simple subroutine adjust(x,increment)
    integer, intent(inout) :: x(:)
    integer, intent(in) :: increment
    x=x+shifted(increment)
  end subroutine
end module
program demo
  use pure_simple_math
  implicit none
  integer :: a(3)
  a=2
  call adjust(increment=1,x=a)
  print *,a,total(a)
end program
