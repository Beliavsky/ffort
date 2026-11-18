module m
implicit none
contains
subroutine tick()
integer,save::n=0
call bump(n)
print *,n
end subroutine
subroutine bump(x)
integer,intent(inout)::x
x=x+1
end subroutine
end module
program p
use m
implicit none
call tick()
call tick()
end program
