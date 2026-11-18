! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x(5),y(5),z(5)
  integer :: i, j, before, after, ticks
  x=[-0.75d0,-0.5d0,0.0d0,0.25d0,0.75d0]
  y=[1.0d0,-1.0d0,2.0d0,-2.0d0,4.0d0]
  before=17
  after=29
  ticks=0
  i=41
  j=43
  z=-99.0d0
  where(x>=0.0)
    z=asin(x)
  elsewhere
    z=-asin(x)
  end where
  after=before+after
  print *, z
  print *, before,after,i,j,ticks
end program p
