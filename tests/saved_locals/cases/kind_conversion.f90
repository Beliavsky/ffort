module m
implicit none
contains
subroutine tick()
integer,save::n=3.9
n=n+1
print *,n
end subroutine
end module
program p
use m
implicit none
call tick()
call tick()
end program
