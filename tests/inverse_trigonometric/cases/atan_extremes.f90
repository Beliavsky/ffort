! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x
  x=huge(0d0)
  print *, atan(x),atan(-x),atan(tiny(x)),atan(-tiny(x))
end program p
