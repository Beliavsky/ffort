function directory_exists(xfile) result(tf)
character (len=*), intent(in) :: xfile
logical                       :: tf
integer                       :: nlen
character (len=1)             :: last_char
nlen = len_trim(xfile)
if (nlen > 0) then
   last_char = xfile(nlen:nlen)
   if (last_char == "\" .or. last_char == "/") then
      inquire (file=xfile(1:nlen-1),exist=tf)
      print*,"in directory_exists ",trim(xfile(1:nlen-1)),tf !! debug
      return
   end if
end if
inquire (file=xfile,exist=tf)
! print*,trim(xfile)," ",tf !! debug
end function directory_exists
!
