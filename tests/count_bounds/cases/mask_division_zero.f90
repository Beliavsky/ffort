module m
implicit none
contains
subroutine work(x)
integer,intent(in)::x(:)

integer::a(count(4/x>0))

print *,123
end subroutine
end module
program p
use m
implicit none
call work([1,0])
end program
