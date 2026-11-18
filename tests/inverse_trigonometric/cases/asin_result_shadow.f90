! SPDX-License-Identifier: MIT
program p
  implicit none
  print *, f(5)
contains
  integer function f(x) result(asin)
    integer,intent(in) :: x
    asin=x
  end function
end program p
