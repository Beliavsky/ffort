module m
implicit none
contains
subroutine tick()
integer::n
save n
n=1
end subroutine
end module
program p
use m
implicit none
call tick()
call tick()
end program
