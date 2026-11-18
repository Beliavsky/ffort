! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x
  x=0.0
  print *, asin(-1.0), asin(0.0), asin(1.0)
  print *, kind(asin(x))
end program p
