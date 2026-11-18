! SPDX-License-Identifier: MIT
program p
  implicit none
  print *, atan(4)
contains
  integer function atan(x)
    integer,intent(in) :: x
    atan=x
  end function
end program p
