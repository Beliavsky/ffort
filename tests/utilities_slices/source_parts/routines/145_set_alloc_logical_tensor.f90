subroutine set_alloc_logical_tensor(xx,yy)
logical, intent(in)               :: xx(:,:,:)
logical, intent(out), allocatable :: yy(:,:,:)
allocate (yy(size(xx,1),size(xx,2),size(xx,3)))
yy = xx
end subroutine set_alloc_logical_tensor
!
