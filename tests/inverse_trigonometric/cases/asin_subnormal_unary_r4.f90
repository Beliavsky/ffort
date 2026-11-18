! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: s
  s=tiny(0.0)*epsilon(0.0)
  print *, asin(s),asin(-s)
end program
