! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x(2,1,2)
  x(1,1,1)=1d0
  x(2,1,1)=-1d0
  x(1,1,2)=1d0
  x(2,1,2)=-1d0
  print *, atan2(1d0,x),shape(atan2(1d0,x))
end program p
