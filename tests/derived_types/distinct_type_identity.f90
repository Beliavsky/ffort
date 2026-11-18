module records
implicit none
type :: pair
integer :: first
real :: second
end type
type :: other
integer :: first
real :: second
end type
end module
program main
use records
type(pair)::p
type(other)::q
p=pair(1,2.0)
q=p
end program
