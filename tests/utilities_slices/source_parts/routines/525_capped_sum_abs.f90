pure function capped_sum_abs(xx,cap) result(yy)
! return vector that is scaled so that the sum of its absolute values does not exceed cap
real(kind=dp), intent(in) :: xx(:)
real(kind=dp), intent(in) :: cap
real(kind=dp)             :: yy(size(xx))
real(kind=dp)             :: sum_abs
yy = 0.0_dp
if (cap > 0.0_dp) then
   sum_abs = sum(abs(xx))
   if (sum_abs > cap) yy = xx * cap/sum_abs
end if
end function capped_sum_abs
!
