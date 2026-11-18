function default_character_nlen(nlen,def,opt) result(yy)
! return string of length nlen that is opt if it is present, otherwise def (character arguments and result)
integer          , intent(in)           :: nlen
character (len=*), intent(in)           :: def
character (len=*), intent(in), optional :: opt
character (len=nlen)                    :: yy
if (present(opt)) then
   yy = opt
else
   yy = def
end if
end function default_character_nlen
!
