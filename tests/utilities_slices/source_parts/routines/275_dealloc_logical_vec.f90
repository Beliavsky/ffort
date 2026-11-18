pure subroutine dealloc_logical_vec(xx)
logical, intent(in out), allocatable :: xx(:)
if (allocated(xx)) deallocate (xx)
end subroutine dealloc_logical_vec
!
