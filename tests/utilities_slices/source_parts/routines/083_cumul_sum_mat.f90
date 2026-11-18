function cumul_sum_mat(xx) result(yy)
! compute the cumulative sum of xx(:)
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp)             :: yy(size(xx,1),size(xx,2))
integer                   :: i,n1,n2
n1 = size(xx,1)
n2 = size(xx,2)
if (n1 < 1 .or. n2 < 1) return
yy(1,:) = xx(1,:)
do i=2,n1
   yy(i,:) = yy(i-1,:) + xx(i,:)
end do
end function cumul_sum_mat
!
