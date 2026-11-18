elemental function logistic(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = 1/(1 + exp(-xx))
end function logistic
!
