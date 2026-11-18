module m
implicit none
contains
pure integer(8) function f(n) result(v)
integer,intent(in)::n
v=2147483648_8
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
call run(3)
end program
