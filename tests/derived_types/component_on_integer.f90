module records
implicit none
type :: pair
integer :: first
real :: second
end type
end module
program main
use records
integer::n
n%first=1
end program
