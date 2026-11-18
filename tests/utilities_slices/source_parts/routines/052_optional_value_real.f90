elemental function optional_value_real(xdef,xopt) result(yy)
! set yy to (xopt,xdef) if xopt (is,is not) PRESENT
real(kind=dp), intent(in)           :: xdef
real(kind=dp), intent(in), optional :: xopt
real(kind=dp)                       :: yy
if (present(xopt)) then
   yy = xopt
else
   yy = xdef
end if
end function optional_value_real
!
