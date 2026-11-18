module m
implicit none
contains
subroutine tick()
integer,save::n=0
n=n+1
print *,n
end subroutine
subroutine other()
integer,save::n=100
n=n+1
print *,n
end subroutine
end module
program p
use m
implicit none
call tick()
call other()
call tick()
call other()
end program
