module ops
implicit none
private
public::compute
interface operator(.hidden.)
module procedure twice
end interface
contains
pure integer function twice(x) result(y)
integer,intent(in)::x
y=2*x
end function
pure integer function compute(x) result(y)
integer,intent(in)::x
y=.hidden. x
end function
end module
program main
use ops,only:compute
implicit none
print *,compute(7)
end program
