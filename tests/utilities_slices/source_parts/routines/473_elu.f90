elemental function elu(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
if (xx >= 0.0_dp) then
   yy = xx
else
   yy = exp(xx) - 1.0_dp
end if
end function elu
!
