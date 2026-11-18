function frac_changes(xx) result(yy)
! return the fraction of times xx(i) is not the same as xx(i-1) for logical array xx(:)
logical, intent(in) :: xx(:)
real(kind=dp)       :: yy
integer             :: n
n = size(xx)
if (n < 2) then
   yy = 0.0_dp
   return
end if
yy = count(xx(2:) .neqv. xx(:n-1)) / dble(n-1)
end function frac_changes
!
