elemental function piecewise_func(xx,x1,x2,y1,y2,func) result(yy)
! return y1 for xx <= x1, y2 for xx >= x2, and an interpolant in between
real(kind=dp)    , intent(in) :: xx,x1,x2,y1,y2
character (len=*), intent(in) :: func
real(kind=dp)                 :: yy
real(kind=dp)                 :: x12,ymean,xscaled
ymean = (y1+y2)/2
if (xx <= x1) then
   yy = y1
   return
else if (xx >= x2) then
   yy = y2
   return
end if
x12   = x2 - x1
if (x12 == 0.0_dp) then
   yy = ymean
   return
end if
xscaled = 2*(xx-x1)/x12 - 1
yy = 0.5_dp*(y2-y1)*piecewise_func_unit(xscaled,func) + ymean
end function piecewise_func
!
