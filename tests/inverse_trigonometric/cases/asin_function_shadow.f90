! SPDX-License-Identifier: MIT
program p
  implicit none
  print *, asin(4)
contains
  integer function asin(x)
    integer,intent(in) :: x
    asin=x
  end function
end program p
