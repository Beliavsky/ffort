! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(2,2)
  x=reshape([-1.0, -0.5, 0.5, 1.0],[2,2])
  print *, asin(x), shape(asin(x))
end program p
