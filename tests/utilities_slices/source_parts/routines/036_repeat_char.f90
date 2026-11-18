pure function repeat_char(n,xx) result(yy)
! repeat 1-D array of character variables with xx repeated n times
integer          , intent(in) :: n
character (len=*), intent(in) :: xx
character (len=len(xx))       :: yy(n)
integer                       :: i
yy = (/(xx,i=1,n)/)
end function repeat_char
!
