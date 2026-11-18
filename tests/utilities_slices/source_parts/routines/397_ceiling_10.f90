elemental function ceiling_10(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = 10.0_dp**(ceiling(log10(abs(xx)))) * merge(1,-1,xx>0.0_dp)
end function ceiling_10
!
