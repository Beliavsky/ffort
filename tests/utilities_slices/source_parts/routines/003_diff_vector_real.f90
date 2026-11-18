pure function diff_vector_real(xx) result(yy)
! return the first differences of xx(:) 
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: yy(size(xx)-1)
integer                   :: n
n = size(xx)
if (n > 1) yy = xx(2:)-xx(:n-1)
end function diff_vector_real
!
