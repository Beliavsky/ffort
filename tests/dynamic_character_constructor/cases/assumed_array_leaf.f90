module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x(:)
integer::i
character(len(x))::y(2*size(x))
y=[(x,i=1,2)]
if(size(y)/=4.or.any(y/=['ab','cd','ab','cd']))stop 1
write(*,'(*(a))')y
end subroutine
end module
program p
use m
implicit none
call f(['ab','cd'])
end program
