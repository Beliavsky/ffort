! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: x
  x=1.000001d0
  print *, "must not leak",asin(x)
end program p
