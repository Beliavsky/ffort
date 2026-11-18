elemental function round_less(xspacing,xx) result(yy)
real(kind=dp), intent(in) :: xspacing,xx
real(kind=dp)             :: yy
if (xx < 0.0_dp) then
   yy = -round_up(xspacing,-xx)
   return
end if
if (abs(xspacing) < tiny_real .or. abs(xx) < tiny_real) then
   yy = xx
   return
end if
yy = int(xx/xspacing)*xspacing
end function round_less
!
