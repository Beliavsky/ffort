! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(0,2,3)
  print *, size(asin(x)), shape(asin(x)), kind(asin(x))
end program p
