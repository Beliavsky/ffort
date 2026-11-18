elemental function optional_value_logical(xdef,xopt) result(yy)
! set yy to (xopt,xdef) if xopt (is,is not) PRESENT
logical, intent(in)           :: xdef
logical, intent(in), optional :: xopt
logical                       :: yy
if (present(xopt)) then
   yy = xopt
else
   yy = xdef
end if
end function optional_value_logical
!
