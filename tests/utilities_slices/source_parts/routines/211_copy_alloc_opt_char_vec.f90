subroutine copy_alloc_opt_char_vec(yy,xdef,xopt)
! copy xopt(:) to yy(:) if xopt is present, otherwise copy xdef(:)
character (len=*), intent(in)               :: xdef(:)
character (len=*), intent(in) , optional    :: xopt(:)
character (len=*), intent(out), allocatable :: yy(:)
if (present(xopt)) then
   call copy_alloc_char_vec(xopt,yy)
else
   call copy_alloc_char_vec(xdef,yy)
end if
end subroutine copy_alloc_opt_char_vec
!
