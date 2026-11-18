pure subroutine dealloc_int_vec(xx)
integer, intent(in out), allocatable :: xx(:)
if (allocated(xx)) deallocate (xx)
end subroutine dealloc_int_vec
!
