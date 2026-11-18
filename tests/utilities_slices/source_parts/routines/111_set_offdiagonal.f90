subroutine set_offdiagonal(xod,xx)
! set off-diagonal elements of square matrix x(:,:) to xod
real(kind=dp), intent(in)     :: xod
real(kind=dp), intent(in out) :: xx(:,:)
integer                       :: i,j,n
n = size(xx,1)
if (size(xx,2) /= n) return
do i=1,n
   do j=1,n
      if (i /= j) xx(i,j) = xod
   end do
end do
end subroutine set_offdiagonal
!
