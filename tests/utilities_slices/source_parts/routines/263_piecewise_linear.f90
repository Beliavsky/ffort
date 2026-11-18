elemental function piecewise_linear(xx,x1,x2,y1,y2) result(yy)
! y ranges from y1 to y2 as x varies from x1 to x2 and is constant outside (x1,x2)
real(kind=dp), intent(in) :: xx,x1,x2,y1,y2
real(kind=dp)             :: yy
real(kind=dp)             :: slope,x12
x12 = x2 - x1
if (abs(x12) > 0.0_dp) then
   slope = (y2-y1)/x12
else
   slope = 0.0_dp
end if
if (xx <= x1) then
   yy = y1
else if (xx >= x2) then
   yy = y2
else
   yy = y1 + slope*(xx-x1)
end if
end function piecewise_linear
!
