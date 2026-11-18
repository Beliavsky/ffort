module m
implicit none
contains
subroutine work()
integer::n
character(n)::a
end subroutine
end module m
program test
use m
implicit none

call work()
end program test
