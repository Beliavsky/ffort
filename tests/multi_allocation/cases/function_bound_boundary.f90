module m
implicit none
contains
integer function countme()
countme=2
end function
end module
program p
use m
implicit none
integer,allocatable::a(:),b(:)
allocate(a(countme()),b(2))
end program
