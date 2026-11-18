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
p=pair(first=1,second=2.0)
end program
