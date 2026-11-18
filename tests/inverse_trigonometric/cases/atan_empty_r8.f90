! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x(0,2,3)
  print *, size(atan(x)), shape(atan(x)), kind(atan(x))
end program p
