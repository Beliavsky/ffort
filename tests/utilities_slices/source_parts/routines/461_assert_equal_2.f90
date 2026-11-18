subroutine assert_equal_2(msg,n1,n2)
! print an error message and stop if n1 /= n2
character (len=*), intent(in) :: msg   ! beginning of error message
integer          , intent(in) :: n1,n2
if (n1 /= n2) then
   write (*,"(a,2(1x,i0),a)") msg,n1,n2," must be equal, STOPPING"
   stop
end if
end subroutine assert_equal_2
!
