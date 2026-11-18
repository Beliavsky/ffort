! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(5)
  x=[-1.0, -0.5, 0.0, 0.5, 1.0]
  print *, atan(x)
end program p
