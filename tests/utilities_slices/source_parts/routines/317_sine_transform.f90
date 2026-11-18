elemental function sine_transform(xx,x1,x2,y1,y2) result(yy)
! ranges from y1 to y2 as x varies from x1 to x2
real(kind=dp), intent(in) :: xx,x1,x2,y1,y2
real(kind=dp)             :: yy
real(kind=dp)             :: arg,dx
dx = x2 - x1
if (abs(dx) > tiny_real) then
   arg = 0.5*pi*min(1.0_dp,max(-1.0_dp,-1.0_dp + 2*(xx-x1)/dx))
else
   arg = 0.0_dp
end if
yy = sin(arg)
yy = 0.5_dp*(y2-y1)*yy + 0.5_dp*(y1+y2)
end function sine_transform
!
