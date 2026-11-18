module m
implicit none
contains
subroutine work(x)
character(2),intent(inout)::x(:)
x="x"
end subroutine
end module m
program test
use m
implicit none
character(3)::a(1)=["abc"]
call work(a)
end program test
