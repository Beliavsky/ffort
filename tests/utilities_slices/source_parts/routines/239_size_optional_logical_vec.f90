function size_optional_logical_vec(ix) result(n)
logical, intent(in), optional :: ix(:)
integer                       :: n
if (present(ix)) then
   n = size(ix)
else
   n = 0
end if
end function size_optional_logical_vec
!
