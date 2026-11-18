module ops
implicit none
type :: item
integer::value
end type
interface test
module procedure a,b
end interface
contains
integer function a(x) result(y)
integer,intent(in)::x
y=2*x
end function
integer function b(x) result(y)
type(item),intent(in)::x
y=x%value
end function
end module
program main
use ops
implicit none
type(item)::v
v%value=8
print *,test(3),test(v)
end program
