subroutine assert_zero(icode,msg)
integer          , intent(in) :: icode
character (len=*), intent(in) :: msg
if (icode == 0) return
write (*,"(a,1x,i0,a)") trim(msg),icode,", must be zero, STOPPING"
stop
end subroutine assert_zero
!
