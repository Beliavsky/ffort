module m
implicit none
contains
subroutine work(x)
logical,intent(in)::x(:)

integer::a(count(x))

print *,123
end subroutine
end module
program p
use m
implicit none
logical::v(3)
v(1)=.true.
v(3)=.false.
call work(v)
end program
