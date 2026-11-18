elemental function rbinary(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = merge(1.0_dp,0.0_dp,xx>0.0_dp)
end function rbinary
!
