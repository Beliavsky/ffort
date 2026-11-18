elemental function sine_bound(xx) result(yy)
! takes on value -1 for xx <= -1, 1 for xx >= 1, varies smoothly in between
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = sin(min(pi/2,max(-pi/2,0.5_dp*pi*xx)))
end function sine_bound
!
