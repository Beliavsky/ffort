! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8), allocatable :: x(:)
  allocate(x(3))
  x=[-0.5d0,0d0,0.5d0]
  print *, asin(x)
end program p
