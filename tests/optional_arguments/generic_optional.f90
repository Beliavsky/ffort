module optional_generic
implicit none
interface pick
module procedure ipick,rpick
end interface
contains
pure function ipick(a,b) result(x)
integer,intent(in) :: a
integer,optional,intent(in) :: b
integer :: x
x=a
if(present(b)) x=b
end function
pure function rpick(a,b) result(x)
real,intent(in) :: a
real,optional,intent(in) :: b
real :: x
x=a
if(present(b)) x=b
end function
end module
program generic_optional_test
use optional_generic
implicit none
print *,pick(1),pick(1.5),pick(b=3,a=1),pick(a=1.5,b=2.5)
end program
