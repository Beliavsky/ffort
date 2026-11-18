! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x
  x=0.0
  print *, atan(-1.0), atan(0.0), atan(1.0)
  print *, kind(atan(x))
end program p
