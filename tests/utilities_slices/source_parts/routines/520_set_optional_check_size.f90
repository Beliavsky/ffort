subroutine set_optional_check_size(xx,xopt,xdefault)
! set xopt(:) to xx(:) if xopt(:) is present and the same size as xx(:)
! otherwise, set xopt(:) to xdefault if xdefault is present
real(kind=dp), intent(in)               :: xx(:)
real(kind=dp), intent(in out), optional :: xopt(:)
real(kind=dp), intent(in)    , optional :: xdefault
if (present(xopt)) then
   if (size(xx) == size(xopt)) then
      xopt = xx
   else if (present(xdefault)) then
      xopt = xdefault
   end if
end if           
end subroutine set_optional_check_size
!
