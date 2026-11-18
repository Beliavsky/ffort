subroutine assert_equal_3(msg,n1,n2,n3)
integer          , intent(in) :: n1,n2,n3
character (len=*), intent(in) :: msg
if (n1 /= n2 .or. n1 /= n3) then
   write (*,"(a,3(1x,i0),a)") msg,n1,n2,n3," must be equal, STOPPING"
   stop
end if
end subroutine assert_equal_3
!
