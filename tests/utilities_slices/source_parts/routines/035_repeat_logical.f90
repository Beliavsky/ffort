pure function repeat_logical(n,xx) result(yy)
! repeat 1-D array of logical variables with xx repeated n times
integer          , intent(in) :: n
logical          , intent(in) :: xx
logical                       :: yy(n)
integer                       :: i
yy = [(xx,i=1,n)]
end function repeat_logical
!
