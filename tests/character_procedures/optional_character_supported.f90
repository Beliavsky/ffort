module m
implicit none
contains
subroutine work(a)
character(*),optional,intent(in)::a(:)
end subroutine
end module m
program test
use m
implicit none
character(3)::a(1)
call work(a)
end program test
