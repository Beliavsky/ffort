! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: s,z
  s=tiny(0d0)*epsilon(0d0)
  z=-0d0
  print *, atan2(s,0d0),atan2(-s,z),atan2(z,s),atan2(0d0,-s)
  print *, atan2(s,s),atan2(-s,-s),atan2(s,1d0),atan2(-s,1d0)
end program
