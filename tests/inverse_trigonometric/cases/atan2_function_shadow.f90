! SPDX-License-Identifier: MIT
program p
  implicit none
  print *, atan2(4)
contains
  integer function atan2(x)
    integer,intent(in) :: x
    atan2=x
  end function
end program p
