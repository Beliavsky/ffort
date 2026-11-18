program p
implicit none

print *,identity(1.125d0)
contains
real(kind=4+4) function identity(xx) result(yy)
real(kind=4+4),intent(in)::xx
yy=xx
end function
end program p
