! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: z
  z=-0d0
  print *, atan2(z,1d0), atan2(0d0,1d0)
end program p
