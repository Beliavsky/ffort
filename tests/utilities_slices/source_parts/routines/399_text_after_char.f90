elemental function text_after_char(xx,xchar,back) result(yy)
character (len=*), intent(in) :: xx,xchar
character (len=len(xx))       :: yy
logical          , intent(in), optional :: back
integer                       :: ipos,nlen
nlen = len(xx)
if (nlen < 1) return
ipos = index(xx,xchar,back=back)
if (ipos == 0) then
   yy = xx
else if (ipos == nlen) then
   yy = ""
else
   yy = xx(ipos+1:)
end if
end function text_after_char
!
