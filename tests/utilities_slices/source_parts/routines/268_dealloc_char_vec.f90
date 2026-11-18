pure subroutine dealloc_char_vec(xx)
character (len=*), intent(in out), allocatable :: xx(:)
if (allocated(xx)) deallocate (xx)
end subroutine dealloc_char_vec
!
