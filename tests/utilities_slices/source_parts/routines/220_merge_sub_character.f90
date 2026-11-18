elemental subroutine merge_sub_character(xx,tf,xtrue,xfalse)
! set xx to xtrue (xfalse) if tf is true (false)
character (len=*), intent(out) :: xx
logical          , intent(in)  :: tf
character (len=*), intent(in)  :: xtrue,xfalse
if (tf) then
   xx = xtrue
else
   xx = xfalse
end if
end subroutine merge_sub_character
!
