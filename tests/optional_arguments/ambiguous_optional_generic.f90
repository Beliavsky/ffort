module ambiguous_optional
implicit none
interface choose
module procedure one,two
end interface
contains
function one(a) result(x)
integer,optional,intent(in) :: a
integer :: x
x=1
end function
function two(b) result(x)
real,optional,intent(in) :: b
integer :: x
x=2
end function
end module
program ambiguous_optional_test
use ambiguous_optional
implicit none
print *,choose()
end program
