module m
implicit none
contains
pure integer function f(x) result(v)
integer,intent(in)::x(:)
v=size(x)
end function
subroutine run(n)
integer,intent(in)::n
integer::a(f([1,2]))
a=7
print *,size(a)
end subroutine
end module
program p
use m
implicit none
call run(3)
end program
