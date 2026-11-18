function sum_no_overlap_vector(xx,nsum) result(xsum)
! compute non-overlapping nsum-term sums of xx(:)
real(kind=dp), intent(in) :: xx(:)
integer      , intent(in) :: nsum
real(kind=dp)             :: xsum(size(xx)/nsum)
integer                   :: i
do i=1,size(xx)/nsum
   xsum(i) = sum(xx((i-1)*nsum+1:i*nsum))
end do
end function sum_no_overlap_vector
!
