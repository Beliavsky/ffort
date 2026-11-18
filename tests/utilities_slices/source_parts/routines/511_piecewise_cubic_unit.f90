elemental function piecewise_cubic_unit(xx) result(yy)
! cubic function that passes through (-1,1) and (1,1) and has zero slope at x = -1 and x = 1
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
if (xx <= -1.0_dp) then
   yy = -1.0_dp
else if (xx >= 1.0_dp) then
   yy =  1.0_dp
else 
   yy = (3*xx - xx**3)/2
end if
end function piecewise_cubic_unit
!
