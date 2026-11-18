subroutine set_alloc_real_matrix(xx,yy)
! for real matrices xx(:,:) and yy(:,:), allocate yy and set it to xx
real(kind=dp) , intent(in)               :: xx(:,:)
real(kind=dp) , intent(out), allocatable :: yy(:,:)
allocate (yy(size(xx,1),size(xx,2)))
yy = xx
end subroutine set_alloc_real_matrix
!
