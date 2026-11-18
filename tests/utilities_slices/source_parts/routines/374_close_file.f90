subroutine close_file(xfile)
! close a file if it is open
character (len=*), intent(in) :: xfile
integer                       :: iu
inquire(file=xfile,number=iu)
if (iu > -1) close(iu)
end subroutine close_file
!
