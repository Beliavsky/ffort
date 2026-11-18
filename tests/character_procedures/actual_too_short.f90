module m
implicit none
contains
subroutine work(x)
character(3),intent(in)::x(:)
end subroutine
end module m
program test
use m
implicit none
character(2)::a(1)=["ab"]
call work(a)
end program test
