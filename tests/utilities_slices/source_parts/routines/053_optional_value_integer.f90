elemental function optional_value_integer(xdef,xopt) result(yy)
! set yy to (xopt,xdef) if xopt (is,is not) PRESENT
integer, intent(in)           :: xdef
integer, intent(in), optional :: xopt
integer                       :: yy
if (present(xopt)) then
   yy = xopt
else
   yy = xdef
end if
end function optional_value_integer
!
