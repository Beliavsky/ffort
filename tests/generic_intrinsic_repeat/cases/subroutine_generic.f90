module m
implicit none
interface repeat
module procedure custom
end interface
contains
subroutine custom(n)
integer,intent(in)::n
end subroutine
end module
program main
use m
implicit none
print *,repeat('x',2)
end program
