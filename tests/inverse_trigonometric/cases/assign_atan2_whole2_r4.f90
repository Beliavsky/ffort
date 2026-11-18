! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(2),y(2),z(2)
  integer :: i, j, before, after, ticks
  x=[-0.75,-0.5]
  y=[1.0,-1.0]
  before=17
  after=29
  ticks=0
  i=41
  j=43
  z=-99.0
  z=atan2(x,y)
  after=before+after
  print *, z
  print *, before,after,i,j,ticks
end program p
