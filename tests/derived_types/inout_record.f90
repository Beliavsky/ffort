module records
implicit none
type :: pair
integer :: first
real :: second
end type
contains
subroutine update(p)
type(pair),intent(inout)::p
p%first=9
p%second=4.0
end subroutine
end module
program main
use records
type(pair)::p
p=pair(1,2.0)
call update(p)
print*,p%first,p%second
end program
