! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(1,1,1,1)
  x=0.5
  print *, atan2(x,1.0)
end program
