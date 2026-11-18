pure function first_int(vec) result(yy)
integer, intent(in) :: vec(:)
integer             :: yy
if (size(vec) > 0) then
   yy = vec(1)
else
   yy = bad_int
end if
end function first_int
!
