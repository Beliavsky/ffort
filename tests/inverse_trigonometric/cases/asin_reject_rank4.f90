! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(1,1,1,1)
  x=0.5
  print *, asin(x)
end program
