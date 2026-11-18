module records
implicit none
type :: pair
integer :: first
real :: second
end type
end module
program main
use records
type(pair)::p
p%second=2.5
p%first=7
print*,p%first,p%second
end program
