module m
implicit none
contains
subroutine tick(k)
integer,intent(in)::k
integer,save::n=k
n=n+1
print *,n
end subroutine
end module
program p
use m
implicit none
call tick(2)
end program
