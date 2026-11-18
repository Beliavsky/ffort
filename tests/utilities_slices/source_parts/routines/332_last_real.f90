function last_real(n,xx) result(yy)
! return a vector with the last min(n,size(xx)) observations of xx
integer, intent(in) :: n
real(kind=dp), intent(in)  :: xx(:)
real(kind=dp), allocatable :: yy(:)
integer                    :: i1,nobs
nobs = size(xx)
if (n < 1 .or. nobs < 1) then
   allocate (yy(0))
   return
end if
i1 = max(1,nobs-n+1)
call set_alloc(xx(i1:),yy)
end function last_real
!
