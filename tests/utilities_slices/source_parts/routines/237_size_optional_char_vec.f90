function size_optional_char_vec(ix) result(n)
character (len=*), intent(in), optional :: ix(:)
integer                                 :: n
if (present(ix)) then
   n = size(ix)
else
   n = 0
end if
end function size_optional_char_vec
!
