! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(2,1,2)
  x(1,1,1)=-1.0
  x(2,1,1)=-0.5
  x(1,1,2)=0.5
  x(2,1,2)=1.0
  print *, asin(x), shape(asin(x))
end program p
