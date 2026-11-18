module records
implicit none
type :: pair
integer :: first
real :: second
end type
contains
subroutine update(p)
type(pair),intent(in)::p
p%first=4
end subroutine
end module
program main
use records
type(pair)::p
p=pair(1,2.0)
call update(p)
end program
