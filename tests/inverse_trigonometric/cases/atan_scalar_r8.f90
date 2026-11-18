! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x
  x=0d0
  print *, atan(-1d0), atan(0d0), atan(1d0)
  print *, kind(atan(x))
end program p
