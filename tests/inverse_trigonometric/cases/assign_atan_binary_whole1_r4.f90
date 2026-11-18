! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(1),y(1),z(1)
  integer :: i, j, before, after, ticks
  x=[-0.75]
  y=[1.0]
  before=17
  after=29
  ticks=0
  i=41
  j=43
  z=-99.0
  z=atan(x,y)
  after=before+after
  print *, z
  print *, before,after,i,j,ticks
end program p
