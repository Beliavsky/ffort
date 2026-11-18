function moving_average(xx,n1,n2) result(xma)
! simple moving average using terms n1 to n2
real(kind=dp), intent(in) :: xx(:)
integer      , intent(in) :: n1,n2
real(kind=dp)             :: xma(size(xx))
integer                   :: i,i1,i2,n,n12
xma = 0.0_dp
n = size(xx)
if (n < 1) return
do i=1,n
   i2 = min(n,max(1,i-n1+1))
   i1 = min(n,max(1,i-n2+1))
   n12 = i2 - i1 + 1
   if (n12 > 0) xma(i) = sum(xx(i1:i2))/n12
end do
end function moving_average
!
