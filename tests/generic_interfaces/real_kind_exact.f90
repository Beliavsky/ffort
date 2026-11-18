module operations
implicit none

interface choose
module procedure a,b
end interface
contains
real(kind=4) function a(x) result(y)
real(kind=4),intent(in)::x
y=2*x
end function
real(kind=8) function b(x) result(y)
real(kind=8),intent(in)::x
y=3*x
end function
end module
program main
use operations
implicit none
print *,choose(1.25_4),choose(1.25_8)

end program
