function base_file_name(fname) result(yy)
! remove extensions (text following the last ".") from Windows file names
character (len=*), intent(in) :: fname
character (len=100)           :: yy
integer                       :: ipos
yy   = short_file_name(fname)
ipos = index(yy,".",back=.true.)
if (ipos > 0) then
   yy = trim(yy(:ipos-1))
end if
end function base_file_name
!
