module records
implicit none
type :: pair
integer :: first(2)
real :: second
end type
end module
program main
use records
type(pair)::p
p%first=1
end program
