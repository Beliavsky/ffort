! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8), allocatable :: x(:)
  allocate(x(3))
  x=[-0.5d0,0d0,0.5d0]
  print *, atan2(x,1d0)
end program p
