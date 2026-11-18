elemental function merge_char(tf,xtrue,xfalse) result(xx)
! return xtrue or xfalse, depending on tf
logical          , intent(in) :: tf
character (len=*), intent(in), optional :: xtrue,xfalse
character (len=1000)          :: xx
if (tf) then
   call set_optional(xx,"",xtrue)
else
   call set_optional(xx,"",xfalse)
end if
end function merge_char
!
