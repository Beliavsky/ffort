module utility_slice
implicit none
integer,parameter :: dp=selected_real_kind(15,307)
real(kind=dp)    , parameter :: tiny_real = 1.0d-10, pi = 3.141592653589793238462643_dp, &
                                bad_real = -999.0_dp
contains
elemental function sine_bound(xx) result(yy)
! takes on value -1 for xx <= -1, 1 for xx >= 1, varies smoothly in between
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = sin(min(pi/2,max(-pi/2,0.5_dp*pi*xx)))
end function sine_bound

elemental function half_sine_bound(xx) result(yy)
! takes on value -1 for xx <= -1, 1 for xx >= 1, varies smoothly in between
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = sin(min(pi/2,max(0.0_dp,0.5_dp*pi*xx)))
end function half_sine_bound

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

elemental function half_sine_transform(xx,x1,x2,y1,y2) result(yy)
! ranges from y1 to y2 as x varies from x1 to x2
real(kind=dp), intent(in) :: xx,x1,x2,y1,y2
real(kind=dp)             :: yy
real(kind=dp)             :: arg,dx
dx = x2 - x1
if (abs(dx) > tiny_real) then
   arg = 0.5*pi*min(1.0_dp,max(0.0_dp,(xx-x1)/dx))
else
   arg = 0.0_dp
end if
yy = sin(arg)
yy = y1 + (y2-y1)*yy ! 0.5_dp*(y2-y1)*yy + 0.5_dp*(y1+y2)
end function half_sine_transform

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
end module
program utility_sine
use utility_slice
implicit none
real(dp)::x(7),m(2,2),z(0)
x=[-2.0_dp,-1.0_dp,-0.5_dp,0.0_dp,0.5_dp,1.0_dp,2.0_dp]
m(:,1)=[-0.5_dp,0.0_dp]
m(:,2)=[0.5_dp,1.0_dp]
print *,sine_bound(x),half_sine_bound(x)
print *,sine_bound(m),half_sine_bound(m)
print *,sine_bound(x(7:1:-2)),sum(sine_bound(z))
print *,sine_transform(x,-1.0_dp,1.0_dp,10.0_dp,20.0_dp)
print *,half_sine_transform(x,-1.0_dp,1.0_dp,10.0_dp,20.0_dp)
print *,sine_transform(m,1.0_dp,1.0_dp,10.0_dp,20.0_dp)
print *,half_sine_transform(m,1.0_dp,1.0_dp,10.0_dp,20.0_dp)
print *,piecewise_sine(x,-1.0_dp,1.0_dp,10.0_dp,20.0_dp)
print *,piecewise_sine(x,1.0_dp,1.0_dp,10.0_dp,20.0_dp)
if (sine_bound(-2.0_dp) /= -1.0_dp) stop 1
if (sine_bound(2.0_dp) /= 1.0_dp) stop 2
if (half_sine_bound(-1.0_dp) /= 0.0_dp) stop 3
if (sine_transform(0.0_dp,1.0_dp,1.0_dp,10.0_dp,20.0_dp) /= 15.0_dp) stop 4
if (half_sine_transform(0.0_dp,1.0_dp,1.0_dp,10.0_dp,20.0_dp) /= 10.0_dp) stop 5
end program
