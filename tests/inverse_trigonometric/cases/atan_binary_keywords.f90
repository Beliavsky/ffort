! SPDX-License-Identifier: MIT
program p
  implicit none
  print *, atan(y=0.5d0,x=-1d0), atan(x=-1d0,y=0.5d0)
  print *, atan(0.5d0,x=-1d0)
end program p
