module ops
implicit none

interface test
module procedure a,b
end interface
contains
real function a(x) result(y)
real,intent(in)::x(:,:)
y=sum(x)
end function
real function b(x) result(y)
real,intent(in)::x
y=2*x
end function
end module
program main
use ops
implicit none
real::v(2,2)
v=1.5
print *,test(v+v),test(2.0)
end program
