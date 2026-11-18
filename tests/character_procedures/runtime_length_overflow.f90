module m
implicit none
contains
subroutine work(n)
integer,intent(in)::n
character(n+1)::a(0)
end subroutine
end module m
program test
use m
implicit none
integer::n
n=2147483647
call work(n)
end program test
