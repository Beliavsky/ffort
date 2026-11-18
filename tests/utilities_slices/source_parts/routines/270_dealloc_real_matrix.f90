pure subroutine dealloc_real_matrix(xx)
real(kind=dp), intent(in out), allocatable :: xx(:,:)
if (allocated(xx)) deallocate (xx)
end subroutine dealloc_real_matrix
!
