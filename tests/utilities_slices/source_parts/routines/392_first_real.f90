pure function first_real(vec) result(yy)
real(kind=dp), intent(in) :: vec(:)
real(kind=dp)             :: yy
if (size(vec) > 0) then
   yy = vec(1)
else
   yy = bad_int
end if
end function first_real
!
