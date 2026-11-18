elemental function x_times_logistic(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = xx*logistic(xx)
end function x_times_logistic
!
