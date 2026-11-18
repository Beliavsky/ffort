! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(0,2,3)
  print *, size(atan2(x,1.0)), shape(atan2(x,1.0)), kind(atan2(x,1.0))
end program p
