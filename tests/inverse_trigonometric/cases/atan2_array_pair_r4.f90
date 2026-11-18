! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: y(2,2), x(2,2)
  y=reshape([1.0,1.0,-1.0,-1.0],[2,2])
  x=reshape([1.0,-1.0,1.0,-1.0],[2,2])
  print *, atan2(y,x)
end program p
