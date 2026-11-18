pure function tail_real(xx) result(yy)
! return the last element of xx(:)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: yy
integer                   :: n
n = size(xx)
if (n > 0) then
   yy = xx(n)
else
   yy = bad_real
end if
end function tail_real
!
