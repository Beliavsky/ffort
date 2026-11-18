subroutine set_alloc_real_tensor(xx,yy)
! for real tensors xx(:,:,:) and yy(:,:,:), allocate yy and set it to xx
real(kind=dp) , intent(in)               :: xx(:,:,:)
real(kind=dp) , intent(out), allocatable :: yy(:,:,:)
allocate (yy(size(xx,1),size(xx,2),size(xx,3)))
yy = xx
end subroutine set_alloc_real_tensor
!
