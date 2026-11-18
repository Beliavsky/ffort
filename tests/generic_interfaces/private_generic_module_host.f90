module operations
implicit none
private
public::wrapper
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
integer function wrapper(x) result(y)
integer,intent(in)::x
y=choose(x)
end function
end module
program main
use operations, only: wrapper
implicit none
print *,wrapper(4)

end program
