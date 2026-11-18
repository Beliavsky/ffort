! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x(3),y(3)
  x=[1d0,0d0,-1d0]
  y=[0d0,0d0,1d0]
  print *, "must not leak",atan2(y,x)
end program p
