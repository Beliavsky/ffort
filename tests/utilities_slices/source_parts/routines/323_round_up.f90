elemental function round_up(xspacing,xx) result(yy)
! round xx to a larger magnitude on a grid with spacing xspacing
! For example, round_up(0.5_dp,2.1_dp) = 2.5_dp, round_up(0.5_dp,-2.3_dp) = -2.5_dp
real(kind=dp), intent(in) :: xspacing,xx
real(kind=dp)             :: yy
integer                   :: n
real(kind=dp)             :: xround
if (abs(xspacing) < tiny_real .or. abs(xx) < tiny_real) then
   yy = xx
   return
end if
n = int(xx/xspacing)
xround = n*xspacing
if (xx > 0) then
   if (xx <= xround) then
      yy = xround
   else
      yy = xround + xspacing
   end if
else
   if (xx >= xround) then
      yy = xround
   else
      yy = xround - xspacing
   end if
end if
end function round_up
!
