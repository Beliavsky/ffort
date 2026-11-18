module operations
implicit none
private
public::a
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
use operations, only: choose
implicit none
print *,choose(4)

end program
