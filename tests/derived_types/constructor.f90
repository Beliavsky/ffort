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
p=pair(4,2.5)
print*,p%first,p%second
end program
