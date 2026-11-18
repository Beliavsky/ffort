module m
implicit none
contains
subroutine tick(k)
integer,intent(in),save::k
integer::n
n=k
end subroutine
end module
program p
use m
implicit none
call tick(2)
end program
