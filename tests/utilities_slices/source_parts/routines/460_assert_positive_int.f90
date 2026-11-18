subroutine assert_positive_int(msg,i)
! print an error message and stop if i <= 0
! sample call: call assert_positive("in main, i ",i)
character (len=*), intent(in) :: msg
integer          , intent(in) :: i
if (i <= 0) then
   write (*,"(a,' =',1x,i0,a)") trim(msg),i,", must be > 0, STOPPING"
   stop
end if
end subroutine assert_positive_int
!
