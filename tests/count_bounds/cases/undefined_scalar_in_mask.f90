module m
implicit none
contains
subroutine work(x,n)
integer,intent(in)::x(:),n
integer::a(count(x>n))
print *,123
end subroutine
end module
program p
use m
implicit none
integer::n
call work([1,2],n)
end program
