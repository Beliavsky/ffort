function sum_no_overlap_matrix(xx,nsum) result(xsum)
! compute non-overlapping nsum-term sums of xx(:)
real(kind=dp), intent(in) :: xx(:,:)
integer      , intent(in) :: nsum
real(kind=dp)             :: xsum(size(xx,1)/nsum,size(xx,2))
integer                   :: i,j
do i=1,size(xx,1)/nsum
   do j=1,size(xx,2)
      xsum(i,j) = sum(xx((i-1)*nsum+1:i*nsum,j))
   end do
end do
end function sum_no_overlap_matrix
!
