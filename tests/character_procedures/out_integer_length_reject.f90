module m
implicit none
contains
subroutine work(n)
integer,intent(out)::n
character(n)::a
end subroutine
end module m
program test
use m
implicit none
integer::n
call work(n)
end program test
