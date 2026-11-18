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
p=pair(4,3.0)
p%first=p%first+int(p%second)
print*,p%first
end program
