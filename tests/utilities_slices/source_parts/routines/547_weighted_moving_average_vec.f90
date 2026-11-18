pure function weighted_moving_average_vec(xx,wgt) result(xma)
! simple moving average with nma terms
! uses growing average for xma(1:nma-1)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp), intent(in) :: wgt(:)
real(kind=dp)             :: xma(size(xx))
integer                   :: i,m,n,nma
nma = size(wgt)
if (nma < 1) return
n = size(xx)
if (n < 1) return
if (nma > n) then
   xma = moving_average_vec(xx,n)
   return
end if
do i=1,nma-1
   m = min(i,nma)
   xma(i) = sum(xx(i-m+1:i))/m       
end do
do i=nma,n
   xma(i) = sum(xx(i-nma+1:i)*wgt(nma:1:-1))
end do
end function weighted_moving_average_vec
!
