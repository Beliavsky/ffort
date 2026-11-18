module records
implicit none
type :: pair
integer :: first
real :: first
end type
end module
program main
use records
type(pair)::p
p=pair(1,2)
end program
