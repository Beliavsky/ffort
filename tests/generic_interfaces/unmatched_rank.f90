module operations
implicit none

interface choose
module procedure a,b
end interface
contains
integer function a(x) result(y)
integer,intent(in)::x
y=2*x
end function
integer function b(x) result(y)
logical,intent(in)::x
y=0
if(x) y=99
end function
end module
program main
use operations
implicit none
integer::v(2)=[1,2]
print *,choose(v)

end program
