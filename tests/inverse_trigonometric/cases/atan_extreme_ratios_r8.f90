! SPDX-License-Identifier: MIT
program p
  implicit none
  real(8) :: h,t
  h=huge(0d0)
  t=tiny(0d0)
  print *, atan(h,h),atan(h,-h),atan(-h,h),atan(-h,-h)
  print *, atan(t,h),atan(-t,h),atan(h,t),atan(-h,t)
  print *, atan(t,-h),atan(-t,-h)
end program
