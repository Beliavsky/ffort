function num_unique_char(xx) result(nq)
character (len=*), intent(in) :: xx(:)
integer                       :: nq
integer                       :: ipos(size(xx))
call unique_char(xx,ipos,nq)
end function num_unique_char
!
