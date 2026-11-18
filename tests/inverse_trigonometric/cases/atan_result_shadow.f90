! SPDX-License-Identifier: MIT
program p
  implicit none
  print *, f(5)
contains
  integer function f(x) result(atan)
    integer,intent(in) :: x
    atan=x
  end function
end program p
