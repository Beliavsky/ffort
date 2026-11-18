module records
implicit none
type :: pair
integer :: first
real :: second
end type
contains
function make(n) result(p)
integer,intent(in)::n
type(pair)::p
p%first=n
p%second=real(n)
end function
end module
program main
use records
type(pair)::p
p=make(6)
print*,p%first,p%second
end program
