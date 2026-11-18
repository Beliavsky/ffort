module m
implicit none
contains
pure integer function f(n) result(v)
integer,intent(in)::n
v=n+1
end function
subroutine run(n)
integer,intent(in)::n
integer(kind=f(3))::a
a=0
end subroutine
end module
program p
use m
implicit none
call run(3)
end program
