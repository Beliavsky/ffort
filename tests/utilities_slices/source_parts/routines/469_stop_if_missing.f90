subroutine stop_if_missing(xx,yy,msg)
character (len=*), intent(in) :: xx(:),yy(:),msg
integer                       :: i,nmiss
nmiss = 0
do i=1,size(xx)
   if (all(yy /= xx(i))) then
      nmiss = nmiss + 1
      if (nmiss == 1) write (*,"(/,a)") msg
      write (*,"(a)") trim(xx(i))
   end if
end do
if (nmiss > 0) stop "STOPPED in stop_if_missing()"
end subroutine stop_if_missing
!
