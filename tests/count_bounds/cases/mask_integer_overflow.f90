module m
implicit none
contains
subroutine work(x)
integer,intent(in)::x(:)

integer::a(count(x+1>0))

print *,123
end subroutine
end module
program p
use m
implicit none
call work([2147483647])
end program
