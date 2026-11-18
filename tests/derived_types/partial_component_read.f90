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
p%first=5
print*,p%first
end program
