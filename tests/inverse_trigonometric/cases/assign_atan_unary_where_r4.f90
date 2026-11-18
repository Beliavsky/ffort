! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(5),y(5),z(5)
  integer :: i, j, before, after, ticks
  x=[-0.75,-0.5,0.0,0.25,0.75]
  y=[1.0,-1.0,2.0,-2.0,4.0]
  before=17
  after=29
  ticks=0
  i=41
  j=43
  z=-99.0
  where(x>=0.0)
    z=atan(x)
  elsewhere
    z=-atan(x)
  end where
  after=before+after
  print *, z
  print *, before,after,i,j,ticks
end program p
