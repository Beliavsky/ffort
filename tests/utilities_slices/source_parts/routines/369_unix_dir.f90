function unix_dir(dir) result(yy)
character (len=*), intent(in) :: dir
character (len=1000)          :: yy
integer                       :: nlen
nlen = len(dir)
if (nlen < 2) then
   yy = replace_char(dir,"\","/")
   return
end if
if (dir(2:2) == ":") then
   yy = "/mnt/" // dir(1:1) // trim(replace_char(dir(3:),"\","/"))
else
   yy = replace_char(dir,"\","/")
end if
end function unix_dir
!
