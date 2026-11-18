elemental function sgn_real(xx,thresh,smooth) result(yy)
! return sign of xx (-1,0,1)
real(kind=dp), intent(in)           :: xx
real(kind=dp), intent(in), optional :: thresh
logical      , intent(in), optional :: smooth
real(kind=dp)                       :: yy
if (present(thresh)) then
   if (abs(xx) < thresh) then
      if (present_and_false(smooth)) then
         yy = 0.0_dp
      else
         yy = xx/thresh
      end if
   else if (xx >= thresh) then
      yy =  1.0_dp
   else
      yy = -1.0_dp
   end if
else
   if (xx == 0.0_dp) then
      yy = 0.0_dp
   else if (xx > 0.0_dp) then
      yy = 1.0_dp
   else
      yy = -1.0_dp
   end if
end if
end function sgn_real
!
