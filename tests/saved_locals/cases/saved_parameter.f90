module m
implicit none
contains
subroutine tick()
integer,parameter,save::n=0
print *,n
end subroutine
end module
program p
use m
implicit none
call tick()
call tick()
end program
