! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: z
  z=-0.0
  print *, atan(0.0,-1.0),atan(z,-1.0)
  print *, atan(1.0,0.0),atan(-1.0,z)
  print *, atan(z,1.0)
end program p
