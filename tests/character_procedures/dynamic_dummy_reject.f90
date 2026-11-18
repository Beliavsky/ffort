module m
implicit none
contains
subroutine work(n,a)
integer,intent(in)::n
character(n),intent(in)::a
end subroutine
end module m
program test
use m
implicit none
character(3)::a
integer::n
n=3
call work(n,a)
end program test
