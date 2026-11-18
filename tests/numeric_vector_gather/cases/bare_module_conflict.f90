module m
implicit none
integer::a(3)
contains
subroutine take(x)
integer,intent(in)::x(:)
print *,a(1),x(1)
end subroutine
end module
program p
use m
implicit none
a=1
call take(a([1]))
end program
