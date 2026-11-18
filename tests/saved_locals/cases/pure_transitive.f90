module m
implicit none
contains
subroutine tick()
integer,save::n=0
n=n+1
end subroutine
pure subroutine outer()
call tick()
end subroutine
end module
program p
use m
implicit none
call outer()
end program
