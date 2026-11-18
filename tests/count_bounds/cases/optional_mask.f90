module m
implicit none
contains
subroutine work(x)
logical,intent(in),optional::x(:)

integer::a(count(x))

a=7
end subroutine
end module
program p
use m
implicit none
call work([.true.])
end program
