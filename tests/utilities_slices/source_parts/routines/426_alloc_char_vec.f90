pure subroutine alloc_char_vec(n,xx)
integer          , intent(in)                         :: n
character (len=*), intent(out), allocatable, optional :: xx(:) 
if (present(xx)) allocate(xx(n))
end subroutine alloc_char_vec
!
