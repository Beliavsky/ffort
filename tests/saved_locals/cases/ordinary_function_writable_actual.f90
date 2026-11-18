module m
implicit none
contains
integer function tick() result(v)
integer,save::n=0
call bump(n)
v=n
end function
subroutine bump(x)
integer,intent(inout)::x
x=x+1
end subroutine
end module
program p
use m
implicit none
print *,tick()
end program
