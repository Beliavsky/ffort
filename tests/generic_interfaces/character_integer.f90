module ops
implicit none

interface test
module procedure a,b
end interface
contains
integer function a(x) result(y)
integer,intent(in)::x
y=2*x
end function
integer function b(x) result(y)
character(len=*),intent(in)::x
y=0
if(x=='hello') y=5
end function
end module
program main
use ops
implicit none
print *,test(3),test('hello')
end program
