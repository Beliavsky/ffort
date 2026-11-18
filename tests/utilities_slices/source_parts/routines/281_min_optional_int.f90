elemental function min_optional_int(ii,jj) result(mmin)
! return the minimum of ii and jj if jj is present, otherwise ii
integer, intent(in)           :: ii
integer, intent(in), optional :: jj
integer                       :: mmin
if (present(jj)) then
   mmin = min(ii,jj)
else
   mmin = ii
end if
end function min_optional_int
!
