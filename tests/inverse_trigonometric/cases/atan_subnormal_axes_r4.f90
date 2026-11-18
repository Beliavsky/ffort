! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: s,z
  s=tiny(0.0)*epsilon(0.0)
  z=-0.0
  print *, atan(s,0.0),atan(-s,z),atan(z,s),atan(0.0,-s)
  print *, atan(s,s),atan(-s,-s),atan(s,1.0),atan(-s,1.0)
end program
