elemental subroutine set_optional_character(xx,xdef,xopt)
! set xx to (xopt,xdef) if xopt (is,is not) PRESENT
character(len=*), intent(out)          :: xx
character(len=*), intent(in)           :: xdef
character(len=*), intent(in), optional :: xopt
if (present(xopt)) then
   xx = xopt
else
   xx = xdef
end if
end subroutine set_optional_character
!
