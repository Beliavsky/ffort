pure subroutine dealloc_real_vec(xx)
real(kind=dp), intent(in out), allocatable :: xx(:)
if (allocated(xx)) deallocate (xx)
end subroutine dealloc_real_vec
!
