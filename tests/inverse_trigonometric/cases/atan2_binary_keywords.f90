! SPDX-License-Identifier: MIT
program p
  implicit none
  print *, atan2(y=0.5d0,x=-1d0), atan2(x=-1d0,y=0.5d0)
  print *, atan2(0.5d0,x=-1d0)
end program p
