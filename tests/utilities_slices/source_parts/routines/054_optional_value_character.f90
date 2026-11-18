elemental function optional_value_character(xdef,xopt) result(yy)
! set yy to (xopt,xdef) if xopt (is,is not) PRESENT
character (len=*), intent(in)           :: xdef
character (len=*), intent(in), optional :: xopt
character (len=len(xdef))               :: yy
if (present(xopt)) then
   yy = xopt
else
   yy = xdef
end if
end function optional_value_character
!
