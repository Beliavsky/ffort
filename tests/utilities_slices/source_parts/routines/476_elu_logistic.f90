elemental function elu_logistic(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = xx*logistic(xx) + (1-logistic(xx))*(exp(xx) - 1.0_dp) 
end function elu_logistic
!
