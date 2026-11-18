subroutine assert_less(msg,n1,n2)
integer          , intent(in) :: n1,n2
character (len=*), intent(in) :: msg
if (n1 >= n2) then
   write (*,"(a,2(1x,i0),a)") msg,n1,n2," need n1 < n2, STOPPING"
   stop
end if
end subroutine assert_less
!
