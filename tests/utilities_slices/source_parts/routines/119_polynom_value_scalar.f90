pure function polynom_value_scalar(xx,xpoly) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp), intent(in) :: xpoly(:) ! polynomial coefficients, starting with the lowest order (constant term)
real(kind=dp)             :: yy
real(kind=dp)             :: xpow
integer                   :: i,ndeg
ndeg = size(xpoly) - 1
yy   = 0.0_dp
xpow = 1.0_dp
do i=1,ndeg+1
   yy = yy + xpoly(i)*xpow
   xpow = xpow * xx
end do
end function polynom_value_scalar
!
