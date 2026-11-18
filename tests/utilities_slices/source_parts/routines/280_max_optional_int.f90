elemental function max_optional_int(ii,jj) result(mmax)
integer, intent(in)           :: ii
integer, intent(in), optional :: jj
integer                       :: mmax
if (present(jj)) then
   mmax = max(ii,jj)
else
   mmax = ii
end if
end function max_optional_int
!
