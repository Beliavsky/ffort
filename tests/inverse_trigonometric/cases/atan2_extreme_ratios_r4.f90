! SPDX-License-Identifier: MIT
program p
  implicit none
  real :: h,t
  h=huge(0.0)
  t=tiny(0.0)
  print *, atan2(h,h),atan2(h,-h),atan2(-h,h),atan2(-h,-h)
  print *, atan2(t,h),atan2(-t,h),atan2(h,t),atan2(-h,t)
  print *, atan2(t,-h),atan2(-t,-h)
end program
