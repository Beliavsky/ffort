! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(5),y(5),z(11)
  integer :: i, j, before, after, ticks
  x=[-0.75,-0.5,0.0,0.25,0.75]
  y=[1.0,-1.0,2.0,-2.0,4.0]
  before=17
  after=29
  ticks=0
  i=41
  j=43
  z=-99.0
  z(2:10:2)=atan2(x(5:1:-1),y(5:1:-1))
  after=before+after
  print *, z
  print *, before,after,i,j,ticks
end program p
