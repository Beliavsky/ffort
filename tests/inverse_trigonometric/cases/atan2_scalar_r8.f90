! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x
  x=0d0
  print *, atan2(-1d0,1d0), atan2(0d0,1d0), atan2(1d0,1d0)
  print *, kind(atan2(x,1d0))
end program p
