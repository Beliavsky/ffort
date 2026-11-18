module m
implicit none
contains
subroutine work(n)
integer,intent(in)::n
character(n)::a(0)
end subroutine
end module m
program test
use m
implicit none
integer::n
n=65537
call work(n)
end program test
