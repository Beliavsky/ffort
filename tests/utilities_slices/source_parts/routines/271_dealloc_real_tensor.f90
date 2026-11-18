pure subroutine dealloc_real_tensor(xx)
real(kind=dp), intent(in out), allocatable :: xx(:,:,:)
if (allocated(xx)) deallocate (xx)
end subroutine dealloc_real_tensor
!
