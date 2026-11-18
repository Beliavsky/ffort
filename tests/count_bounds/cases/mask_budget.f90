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
logical::v(100)
v=.true.
call work(v)
end program
