module m
implicit none
contains
pure integer function f(n) result(v)
integer,intent(in)::n
v=n+1
end function
subroutine run(n)
integer,intent(in)::n
integer::a(f(n))
a=7
print *,size(a)
end subroutine
end module
program p
use m
implicit none
call run(1000000)
end program
