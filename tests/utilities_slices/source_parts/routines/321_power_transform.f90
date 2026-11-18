elemental function power_transform(pow,xx) result(yy)
! signed power transform -- monotonic for all pow
real(kind=dp), intent(in) :: pow
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
if (xx == 0.0_dp) then
   yy = 0.0_dp
   return
end if
yy = merge(1,-1,xx>0)*abs(xx)**pow
end function power_transform
!
