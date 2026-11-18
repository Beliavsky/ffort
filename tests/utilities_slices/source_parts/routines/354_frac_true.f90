function frac_true(xx) result(yy)
logical, intent(in) :: xx(:)
real(kind=dp)       :: yy
yy = count(xx)/dble(max(1,size(xx)))
end function frac_true
!
