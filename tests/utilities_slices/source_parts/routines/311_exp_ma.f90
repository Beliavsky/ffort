function exp_ma(xx,alpha) result(yy)
! exponential moving average
real(kind=dp), intent(in) :: xx(:)
real(kind=dp), intent(in) :: alpha
real(kind=dp)             :: yy(size(xx))
integer                   :: i,n
n = size(xx)
if (n < 1) return
if (alpha == 1.0_dp) then
   yy = xx
   return
end if
yy(1) = xx(1)
do i=2,n
   yy(i) = alpha*xx(i) + (1-alpha)*yy(i-1)
end do
end function exp_ma
!
