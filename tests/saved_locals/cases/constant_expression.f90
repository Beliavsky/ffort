module m
implicit none
contains
subroutine tick()
integer,parameter::base=3
integer,save::n=base*2+1
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
