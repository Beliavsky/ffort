subroutine check_all_equal(vec,msg)
integer          , intent(in) :: vec(:)
character (len=*), intent(in) :: msg
if (.not. all_equal(vec)) then
   write (*,*) msg,vec," must all be equal, STOPPING"
   stop
end if
end subroutine check_all_equal
!
