module records
implicit none
type :: pair
integer :: first
real :: second
end type
end module
program main
use records
type(pair)::p(2)
p(1)=pair(1,2.0)
end program
