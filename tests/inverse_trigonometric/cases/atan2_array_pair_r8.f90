! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: y(2,2), x(2,2)
  y=reshape([1d0,1d0,-1d0,-1d0],[2,2])
  x=reshape([1d0,-1d0,1d0,-1d0],[2,2])
  print *, atan2(y,x)
end program p
