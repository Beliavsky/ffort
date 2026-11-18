! SPDX-License-Identifier: MIT
module m
  implicit none
  interface asin
    module procedure f
  end interface
contains
  integer function f(x)
    integer,intent(in) :: x
    f=x
  end function
end module
program p
  use m
  implicit none
  print *, asin(6)
end program
