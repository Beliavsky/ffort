pure function threshold_weights(xx,wgt_min) result(yy)
! set weights less than wgt_min and renormalize weight so that they sum to one
real(kind=dp), intent(in) :: xx(:),wgt_min
real(kind=dp)             :: yy(size(xx))
integer                   :: n
real(kind=dp)             :: ysum
n = size(xx)
if (n == 0) then
   return
else if (n == 1) then
   yy = 1.0_dp
   return
end if
yy = merge(xx,0.0_dp,xx>=wgt_min)
ysum = sum(yy)
if (ysum > 0) then
   yy = yy/ysum
else
   yy = 1.0_dp/n
end if
end function threshold_weights
!
