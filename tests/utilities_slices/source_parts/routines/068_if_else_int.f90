elemental function if_else_int(tf,itrue,ifalse) result(ii)
logical      , intent(in) :: tf
integer      , intent(in) :: itrue,ifalse
integer                   :: ii
if (tf) then
   ii = itrue
else
   ii = ifalse
end if
end function if_else_int
!
