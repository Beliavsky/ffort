module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i,j
character(len(x))::y(6)
y=[((x,j=1,2),i=1,3)]
if(any(y/=x))stop 1
write(*,'(*(a))')y
end subroutine
end module
program p
use m
implicit none
call f('Q ')
end program
