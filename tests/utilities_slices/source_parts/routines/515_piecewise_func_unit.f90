elemental function piecewise_func_unit(xx,func) result(yy)
! return -1 for xx <= -1, 1 for xx >= 1, and an interpolant in between
real(kind=dp)    , intent(in) :: xx
character (len=*), intent(in) :: func
real(kind=dp)                 :: yy
if (xx <= -1.0_dp) then
   yy = -1.0_dp
   return
else if (xx >= 1.0_dp) then
   yy = 1.0_dp
   return
end if
select case (func)
   case ("cubic")   ; yy = (3*xx - xx**3)/2
   case ("quintic") ; yy = (15*xx - 10*xx**3 + 3*xx**5)/8
   case ("sine")    ; yy = sin(pi*xx/2)
   case ("constant"); yy = 0.0_dp
   case ("linear")  ; yy = xx
   case ("tanh2")   ; yy = tanh(2*xx)
   case ("sqrt")   
      if (xx >= 1.0_dp) then
         yy = 1.0_dp
      else if (xx >= 0.0_dp) then
         yy = sqrt(xx)
      else if (xx > -1.0_dp) then
         yy = -sqrt(-xx)
      else
         yy = -1.0_dp
      end if
   case ("sqnl") ! square nonlinearity
      if (xx >= 1.0_dp) then
         yy = 1.0_dp
      else if (xx >= 0.0_dp) then
         yy = 2*xx - xx**2
      else if (xx > -1.0_dp) then
         yy = 2*xx + xx**2
      else
         yy = -1.0_dp
      end if
   case default     ; yy = xx
end select
end function piecewise_func_unit
!
