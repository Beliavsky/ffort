recursive pure function moving_average_vec(xx,nma) result(xma)
! simple moving average with nma terms
! uses growing average for xma(1:nma-1)
real(kind=dp), intent(in) :: xx(:)
integer      , intent(in) :: nma
real(kind=dp)             :: xma(size(xx))
integer                   :: i,m,n
if (nma < 1) return
n = size(xx)
if (n < 1) return
if (nma > n) then
   xma = moving_average_vec(xx,n)
   return
end if
do i=1,nma
   m = min(i,nma)
   xma(i) = sum(xx(i-m+1:i))/m       
end do
do i=nma+1,n
   xma(i) = xma(i-1) + (xx(i)-xx(i-nma))/nma
end do
end function moving_average_vec
!
