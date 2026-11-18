module records
implicit none
type :: pair
integer :: first
real :: second
end type
end module
program main
use records
type(pair)::p,q
p%first=5
q=p
end program
