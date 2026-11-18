elemental function half_sine_bound(xx) result(yy)
! takes on value -1 for xx <= -1, 1 for xx >= 1, varies smoothly in between
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = sin(min(pi/2,max(0.0_dp,0.5_dp*pi*xx)))
end function half_sine_bound
!
