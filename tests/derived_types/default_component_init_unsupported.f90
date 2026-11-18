module records
implicit none
type :: pair
integer :: first=7
real :: second
end type
end module
program main
use records
type(pair)::p
print*,p%first
end program
