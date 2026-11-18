elemental function num_matching_char(text,char_match) result(nc)
! return the number of characters of text matching char_match
character (len=*), intent(in) :: text
character (len=*), intent(in) :: char_match
integer                       :: i,nc
if (len(char_match) /= 1) then
   nc = -1
   return
end if
nc = 0
do i=1,len(text)
   if (text(i:i) == char_match) nc = nc + 1
end do
end function num_matching_char
!
