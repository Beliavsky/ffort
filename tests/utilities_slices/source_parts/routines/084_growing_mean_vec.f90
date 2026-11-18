function growing_mean_vec(xx) result(yy)
! compute the cumulative sum of xx(:)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: yy(size(xx))
real(kind=dp)             :: ysum(size(xx))
integer                   :: i,n
n = size(xx)
if (n < 1) return
ysum(1) = xx(1)
yy(1)   = ysum(1)
do i=2,n
   ysum(i) = ysum(i-1) + xx(i)
   yy(i)   = ysum(i)/i
end do
end function growing_mean_vec
!
