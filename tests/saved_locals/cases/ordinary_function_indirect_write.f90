module m
implicit none
contains
subroutine tick()
integer,save::n=0
n=n+1
end subroutine
integer function outer() result(v)
call tick()
v=1
end function
end module
program p
use m
implicit none
print *,outer()
end program
