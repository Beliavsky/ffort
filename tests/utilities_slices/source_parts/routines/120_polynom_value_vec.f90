pure function polynom_value_vec(xx,xpoly) result(yy)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp), intent(in) :: xpoly(:) ! polynomial coefficients, starting with the lowest order (constant term)
real(kind=dp)             :: yy(size(xx))
integer                   :: i
forall (i=1:size(xx)) yy(i) = polynom_value_scalar(xx(i),xpoly)
end function polynom_value_vec
!
