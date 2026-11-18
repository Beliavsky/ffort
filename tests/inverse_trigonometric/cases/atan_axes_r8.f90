! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: z
  z=-0d0
  print *, atan(0d0,-1d0),atan(z,-1d0)
  print *, atan(1d0,0d0),atan(-1d0,z)
  print *, atan(z,1d0)
end program p
