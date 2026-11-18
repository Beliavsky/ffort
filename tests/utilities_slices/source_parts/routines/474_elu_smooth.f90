elemental function elu_smooth(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
real(kind=dp)             :: c
if (xx >= 0.0_dp) then
   yy = xx
else if (xx >= -1.0_dp) then
   c  = 1.0_dp + xx
   yy = c*xx + (1-c)*(exp(xx) - 1.0_dp)    
else
   yy = exp(xx) - 1.0_dp
end if
end function elu_smooth
!
