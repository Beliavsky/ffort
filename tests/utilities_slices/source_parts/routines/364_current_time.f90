function current_time(format,print_seconds) result(str)
character (len=*), intent(in)           :: format ! "iso" or not
logical          , intent(in), optional :: print_seconds
character (len=22) :: str
character (len=2)  :: am_pm
integer            :: ival(8),hour
integer, parameter :: iyear = 1, imonth = 2, iday = 3, ihour = 5, iminute = 6, isecond = 7
logical            :: print_seconds_
print_seconds_ = .true.
if (present(print_seconds)) print_seconds_ = print_seconds
call date_and_time(values=ival)
if (format == "iso") then
   if (print_seconds_) then
      write (str,"(i4.4,2('-',i2.2),1x,i2.2,2(':',i2.2))") ival([iyear,imonth,iday,ihour,iminute,isecond])
   else
      write (str,"(i4.4,2('-',i2.2),1x,i2.2,':',i2.2)") ival([iyear,imonth,iday,ihour,iminute])
   end if
else if (format == "24h") then
   if (print_seconds_) then
      write (str,"(2(i2.2,'/'),i4.4,1x,2(i2.2,':'),i2.2)") ival([imonth,iday,iyear,ihour,iminute,isecond])
   else
      write (str,"(2(i2.2,'/'),i4.4,1x,i2.2,':',i2.2)") ival([imonth,iday,iyear,ihour,iminute])
   end if
else if (format == "am_pm") then
   hour = ival(ihour)
   if (hour > 12) then
      hour = hour - 12
      am_pm = "PM"
   else
      am_pm = "AM"
   end if
   if (print_seconds_) then
      write (str,"(2(i2.2,'/'),i4.4,1x,2(i2.2,':'),i2.2,1x,a)") ival([imonth,iday,iyear]),hour,ival([iminute,isecond]),am_pm
   else
      write (str,"(2(i2.2,'/'),i4.4,1x,i2.2,':',i2.2,1x,a)") ival([imonth,iday,iyear]),hour,ival([iminute]),am_pm
   end if
end if
end function current_time
!
