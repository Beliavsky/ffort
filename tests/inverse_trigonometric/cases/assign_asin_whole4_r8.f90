! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x(4),y(4),z(4)
  integer :: i, j, before, after, ticks
  x=[-0.75d0,-0.5d0,0.0d0,0.25d0]
  y=[1.0d0,-1.0d0,2.0d0,-2.0d0]
  before=17
  after=29
  ticks=0
  i=41
  j=43
  z=-99.0d0
  z=asin(x)
  after=before+after
  print *, z
  print *, before,after,i,j,ticks
end program p
