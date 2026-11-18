! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x
  x=0d0
  print *, asin(-1d0), asin(0d0), asin(1d0)
  print *, kind(asin(x))
end program p
