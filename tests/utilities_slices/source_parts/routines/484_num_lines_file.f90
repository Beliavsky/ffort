function num_lines_file(xfile) result(nlines)
character (len=*), intent(in)  :: xfile
integer                        :: nlines
integer                        :: ierr,iu
call get_unit(iu)
nlines = 0
open (unit=iu,file=xfile,action="read",iostat=ierr)
if (ierr /= 0) then
   nlines = -1
   return
end if
do
   read (iu,*,iostat=ierr)
   if (ierr /= 0) exit
   nlines = nlines + 1
end do
close(iu)
end function num_lines_file
!
