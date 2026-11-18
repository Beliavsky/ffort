! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: s
  s=tiny(0d0)*epsilon(0d0)
  print *, asin(s),asin(-s)
end program
