! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x
  x=0.0
  print *, atan2(-1.0,1.0), atan2(0.0,1.0), atan2(1.0,1.0)
  print *, kind(atan2(x,1.0))
end program p
