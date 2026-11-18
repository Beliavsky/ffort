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
p=pair(1,2.0)
q=p
p%first=8
print*,q%first,p%first,q%second
end program
