elemental function signed_power(xx,pow) result(yy)
! signed power transform -- monotonic for all pow
real(kind=dp), intent(in) :: pow
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = power_transform(pow,xx)
end function signed_power
!
