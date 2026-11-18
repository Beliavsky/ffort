module m
implicit none
contains
subroutine tick()
integer,save::n=2147483647
n=n+1
print *,n
end subroutine
end module
program p
use m
implicit none
call tick()
end program
