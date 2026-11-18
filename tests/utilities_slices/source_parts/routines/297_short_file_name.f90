function short_file_name(fname) result(yy)
! remove the directory from a file name
character (len=*), intent(in) :: fname
character (len=100)           :: yy
integer                       :: ipos
ipos = index(fname,"\",back=.true.)
if (ipos < len(yy)) then
   yy = fname(ipos+1:)
else
   yy = fname
end if
end function short_file_name
!
