subroutine copy_alloc_char_vec(xx,yy)
! copy xx(:) to yy(:)
character (len=*), intent(in)               :: xx(:)
character (len=*), intent(out), allocatable :: yy(:)
allocate (yy(size(xx)))
yy = xx
end subroutine copy_alloc_char_vec
!
