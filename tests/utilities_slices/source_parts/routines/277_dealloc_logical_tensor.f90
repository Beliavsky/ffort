pure subroutine dealloc_logical_tensor(xx)
logical, intent(in out), allocatable :: xx(:,:,:)
if (allocated(xx)) deallocate (xx)
end subroutine dealloc_logical_tensor
!
