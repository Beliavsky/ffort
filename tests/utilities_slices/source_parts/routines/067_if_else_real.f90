elemental function if_else_real(tf,xtrue,xfalse) result(xx)
logical      , intent(in) :: tf
real(kind=dp), intent(in) :: xtrue,xfalse
real(kind=dp)             :: xx
if (tf) then
   xx = xtrue
else
   xx = xfalse
end if
end function if_else_real
!
