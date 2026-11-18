module records
implicit none
type, public :: pair
integer :: first
real :: second
end type
end module
program main
use records
type(pair)::p
p=pair(4,2.0)
print*,p%first
end program
