function join_quote(words,sep,quote_char) result(str)
! trim and concatenate a vector of character variables,
! inserting sep between them
character (len=*), intent(in)        :: words(:),sep
character (len=(size(words)-1)*len(sep) + sum(len_trim(words)) + 2*size(words)) :: str
character (len=1), intent(in), optional :: quote_char
integer                              :: i,nw
character (len=1)                    :: quote_char_
quote_char_ = default("'",quote_char)
nw  = size(words)
str = ""
if (nw < 1) then
   return
else
   str = quote_char_ // trim(words(1)) // quote_char_
end if
do i=2,nw
   str = trim(str) // sep // quote_char_ // trim(words(i)) // quote_char_
end do
end function join_quote
!
