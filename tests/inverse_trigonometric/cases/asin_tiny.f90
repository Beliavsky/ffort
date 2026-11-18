! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x
  x=tiny(0d0)
  print *, asin(x),asin(-x)
end program p
