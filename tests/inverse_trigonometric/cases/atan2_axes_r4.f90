! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: z
  z=-0.0
  print *, atan2(0.0,-1.0),atan2(z,-1.0)
  print *, atan2(1.0,0.0),atan2(-1.0,z)
  print *, atan2(z,1.0)
end program p
