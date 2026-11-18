! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x,y
  x=-0.0
  y=-0.0
  print *, "must not leak",atan2(y,x)
end program p
