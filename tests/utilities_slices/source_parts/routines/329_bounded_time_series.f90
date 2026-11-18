function bounded_time_series(xx,ret_min,ret_max) result(yy)
! bound the returns of a time series
real(kind=dp), intent(in) :: xx(:),ret_min,ret_max
real(kind=dp)             :: yy(size(xx))
integer                   :: i,n
real(kind=dp)             :: ret
n = size(xx)
if (n < 1) return
yy(1) = xx(1)
do i=2,n
   ret = xx(i)/xx(i-1) - 1.0_dp
   yy(i) = yy(i-1)*(1+min(ret_max,max(ret_min,ret)))
end do
end function bounded_time_series
!
