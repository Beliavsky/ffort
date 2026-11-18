subroutine assert_equal_4(msg,n1,n2,n3,n4)
integer          , intent(in) :: n1,n2,n3,n4
character (len=*), intent(in) :: msg
if (any([n2,n3,n4] /= n1)) then
   write (*,"(a,4(1x,i0),a)") msg,n1,n2,n3,n4," must be equal, STOPPING"
   stop
end if
end subroutine assert_equal_4
!
