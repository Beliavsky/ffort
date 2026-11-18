pure function cumul_sum_vec(xx) result(yy)
! compute the cumulative sum of xx(:)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: yy(size(xx))
integer                   :: i,n
n = size(xx)
if (n < 1) return
yy(1) = xx(1)
do i=2,n
   yy(i) = yy(i-1) + xx(i)
end do
end function cumul_sum_vec
!
