! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x(2,2)
  x=reshape([-1d0, -0.5d0, 0.5d0, 1d0],[2,2])
  print *, atan(x), shape(atan(x))
end program p
