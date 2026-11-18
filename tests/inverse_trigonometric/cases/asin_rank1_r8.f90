! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x(5)
  x=[-1d0, -0.5d0, 0d0, 0.5d0, 1d0]
  print *, asin(x)
end program p
