! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x,y
  x=0d0
  y=0d0
  print *, "must not leak",atan(y,x)
end program p
