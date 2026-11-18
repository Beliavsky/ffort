module m
implicit none
contains
subroutine tick(k)
integer,intent(in)::k
integer,save::n(k)=0
n=1
end subroutine
end module
program p
use m
implicit none
call tick(2)
end program
