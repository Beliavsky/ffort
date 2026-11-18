! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(2,1,2)
  x(1,1,1)=1.0
  x(2,1,1)=-1.0
  x(1,1,2)=1.0
  x(2,1,2)=-1.0
  print *, atan2(1.0,x),shape(atan2(1.0,x))
end program p
