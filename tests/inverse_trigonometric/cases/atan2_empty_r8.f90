! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x(0,2,3)
  print *, size(atan2(x,1d0)), shape(atan2(x,1d0)), kind(atan2(x,1d0))
end program p
