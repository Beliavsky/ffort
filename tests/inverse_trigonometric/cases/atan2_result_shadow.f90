! SPDX-License-Identifier: MIT
program p
  implicit none
  print *, f(5)
contains
  integer function f(x) result(atan2)
    integer,intent(in) :: x
    atan2=x
  end function
end program p
