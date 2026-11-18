! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: s,z
  s=tiny(0.0)*epsilon(0.0)
  z=-0.0
  print *, atan2(s,0.0),atan2(-s,z),atan2(z,s),atan2(0.0,-s)
  print *, atan2(s,s),atan2(-s,-s),atan2(s,1.0),atan2(-s,1.0)
end program
