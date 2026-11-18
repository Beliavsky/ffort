function interp_two_points(xx,x1,x2,y1,y2,slope_left,slope_right) result(yy)
! linear interpolation between two points
real(kind=dp), intent(in)           :: xx,x1,x2,y1,y2
real(kind=dp), intent(in), optional :: slope_left,slope_right
real(kind=dp)                       :: yy
real(kind=dp)                       :: slope
if (x2 > x1) then
   slope = (y2 - y1) / (x2 - x1)
else
   slope = 0.0_dp
end if
if (xx <= x1) then
   yy = y1 - default(slope,slope_left) *(x1-xx)
else if (xx >= x2) then
   yy = y2 + default(slope,slope_right)*(xx-x2)
else
   yy = y1 + slope*(xx-x1)
end if
end function interp_two_points
!
