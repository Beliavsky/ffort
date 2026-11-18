pure function tail_int(xx) result(yy)
! return the last element of xx(:)
integer, intent(in) :: xx(:)
integer             :: yy
integer             :: n
n = size(xx)
if (n > 0) then
   yy = xx(n)
else
   yy = bad_int
end if
end function tail_int
!
