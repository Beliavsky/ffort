elemental function sech(xx) result(yy)
! hyperbolic secant
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = 1/cosh(xx)
end function sech
!
