function lagged(xx,nlag,fill_value) result(yy)
! return xx(:) with each element shifted by nlag values to the right
real(kind=dp), intent(in)           :: xx(:)
real(kind=dp), intent(in), optional :: fill_value
real(kind=dp)                       :: yy(size(xx))
integer      , intent(in)           :: nlag
integer                             :: n
n = size(xx)
yy = default(0.0_dp,fill_value)
if (nlag == 0) then
   yy = xx
else if (nlag > 0) then
   yy(1+nlag:n) = xx(1:n-nlag)
else if (nlag < 0) then
   yy(1:n+nlag) = xx(1-nlag:n)
end if
end function lagged
!
