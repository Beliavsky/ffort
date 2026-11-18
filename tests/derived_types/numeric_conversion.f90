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
p=pair(3.9,2)
print*,p%first,p%second
end program
