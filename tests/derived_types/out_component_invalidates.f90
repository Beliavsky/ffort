module records
implicit none
type :: pair
integer :: first
real :: second
end type
contains
subroutine update(p)
type(pair),intent(out)::p
p%first=4
end subroutine
end module
program main
use records
type(pair)::p
p=pair(1,2.0)
call update(p)
print*,p%second
end program
