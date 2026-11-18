function now() result(str)
character (len=19) :: str
integer            :: ival(8)
call date_and_time(values=ival)
write (str,"(i4.4,2('-',i2.2),1x,i2.2,2(':',i2.2))") ival([1,2,3,5,6,7])
end function now
!
