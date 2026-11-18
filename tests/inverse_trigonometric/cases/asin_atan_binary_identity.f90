! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x(5)
  x=[-1d0,-0.5d0,0d0,0.5d0,1d0]
  print *, all(atan(x,1d0)==atan2(x,1d0))
  print *, abs(asin(0.5d0)-acos(-1d0)/6d0)<1d-14
end program p
