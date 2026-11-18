! SPDX-License-Identifier: MIT
module m
  implicit none
  interface atan
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
  print *, atan(6)
end program
