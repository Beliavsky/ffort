elemental function piecewise_quintic(xx,x1,x2,y1,y2) result(yy)
! return y1 for xx <= x1, y2 for xx >= x2, and a quintic interpolant in between that has zero 1st and 2nd derivatives at x1 anx x2
real(kind=dp), intent(in) :: xx,x1,x2,y1,y2
real(kind=dp)             :: yy
real(kind=dp)             :: x12
if (xx <= x1) then
   yy = y1
   return
else if (xx >= x2) then
   yy = y2
   return
end if
x12 = x2 - x1
if (x12 == 0.0_dp) then
   yy = (y1 + y2)/2
   return
end if
yy = piecewise_quintic_unit(2*(xx-x1)/x12 - 1)*(y2-y1)/2 + (y1+y2)/2
end function piecewise_quintic
!
