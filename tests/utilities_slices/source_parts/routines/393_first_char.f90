pure function first_char(vec) result(yy)
character (len=*), intent(in) :: vec(:)
character (len=len(vec))      :: yy
if (size(vec) > 0) then
   yy = vec(1)
else
   yy = bad_char
end if
end function first_char
!
