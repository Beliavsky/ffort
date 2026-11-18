! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: s,z
  s=tiny(0d0)*epsilon(0d0)
  z=-0d0
  print *, atan(s,0d0),atan(-s,z),atan(z,s),atan(0d0,-s)
  print *, atan(s,s),atan(-s,-s),atan(s,1d0),atan(-s,1d0)
end program
