elemental function replace_char(text,old_char,new_char) result(new_text)
character (len=*), intent(in) :: text,old_char,new_char
character (len=len(text))     :: new_text
integer                       :: i,nlen
nlen = len(text)
new_text = text
do i=1,nlen
   if (index(old_char,new_text(i:i)) /= 0) new_text(i:i) = new_char
end do
end function replace_char
!
