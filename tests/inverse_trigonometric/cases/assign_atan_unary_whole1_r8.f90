! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x(1),y(1),z(1)
  integer :: i, j, before, after, ticks
  x=[-0.75d0]
  y=[1.0d0]
  before=17
  after=29
  ticks=0
  i=41
  j=43
  z=-99.0d0
  z=atan(x)
  after=before+after
  print *, z
  print *, before,after,i,j,ticks
end program p
