elemental function piecewise_sine(xx,x1,x2,y1,y2) result(yy)
! piecewise sine y ranges from y1 to y2 as x varies from x1 to x2 and is constant outside (x1,x2)
real(kind=dp), intent(in) :: xx,x1,x2,y1,y2
real(kind=dp)             :: yy
real(kind=dp)             :: x12,z
if (xx <= x1) then
   yy = y1
   return
else if (xx >= x2) then
   yy = y2
   return
end if
x12 = x2 - x1
if (x12 == 0.0_dp) return
z  = pi*((xx - x1)/x12 - 0.5_dp)
yy = (y2 - y1)*(1+sin(z))/2 + y1
end function piecewise_sine
!
