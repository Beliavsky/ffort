module m
implicit none
contains
subroutine work(x)
character(*),intent(in)::x(:)
print *,x
end subroutine
end module m
program test
use m
implicit none
character(3)::a(2)
call work(a)
end program test
