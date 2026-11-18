subroutine get_var(ysym,symbols,xx,yy,stop_missing)
! put data for symbol ysym in yy(:)
character (len=*), intent(in) :: symbols(:)
real(kind=dp)    , intent(in) :: xx(:,:)
character (len=*), intent(in) :: ysym
real(kind=dp)    , allocatable, intent(out) :: yy(:)
logical, intent(in), optional :: stop_missing
integer                       :: icol
logical                       :: stop_missing_
stop_missing_ = default(.true.,stop_missing)
icol = match_string_scalar(ysym,symbols)
if (icol /= 0) then
   call set_alloc(xx(:,icol),yy)
else
   write (*,*) "could not find data for '" // trim(ysym) // "'"
   if (stop_missing_) then
      write (*,*) "STOPPING"
      stop
   end if
end if
end subroutine get_var
!
