module m
implicit none
contains
subroutine tick()
integer,save::n=0
n=n+1
print *,n
return
n=99
end subroutine
end module
program p
use m
implicit none
call tick()
call tick()
end program
