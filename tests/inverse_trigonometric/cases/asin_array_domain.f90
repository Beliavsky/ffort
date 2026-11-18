! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: x(3)
  x=[0.0,1.1,1.0]
  print *, "must not leak",asin(x)
end program p
