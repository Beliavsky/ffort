module m
implicit none
contains
subroutine work(x,cut)
integer,intent(in)::x(:),cut
integer::a(count(x>cut))
print *,size(a)
end subroutine
end module
program p
use m
implicit none
integer::x(0),undefined
call work(x,undefined)
end program
