function num_lines_string_first_field(string,xfile) result(nfound)
! return the number of times string is found in first field of lines of file xfile
character (len=*), intent(in) :: string
character (len=*), intent(in) :: xfile
integer                       :: nfound
integer                       :: iu,ierr
character (len=len(string))   :: cc
logical          , parameter  :: debug = .false.
nfound = 0
call get_unit_open_file(xfile,iu,"r")
do
   read (iu,*,iostat=ierr) cc
   if (ierr /= 0) exit
   if (cc == string) nfound = nfound + 1
end do
if (debug) write (*,*) "#times '" // trim(string) // "' found in '" // trim(xfile) // "' =",nfound
close(iu)
end function num_lines_string_first_field
!
