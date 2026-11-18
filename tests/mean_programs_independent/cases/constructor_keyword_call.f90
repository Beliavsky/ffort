program p
implicit none

print *,twice(xx=[1d0,2d0])
contains
real(8) function twice(xx) result(yy)
real(8),intent(in)::xx(:)
yy=2*sum(xx)
end function
end program p
