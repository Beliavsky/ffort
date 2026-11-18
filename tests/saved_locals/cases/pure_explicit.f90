module m
implicit none
contains
pure subroutine tick()
integer,save::n=0
n=n+1
end subroutine
end module
program p
use m
implicit none
call tick()
call tick()
end program
