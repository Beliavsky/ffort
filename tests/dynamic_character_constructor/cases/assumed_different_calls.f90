module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i,j
character(len(x))::y(3)
y=[(x,i=1,3)]
if(any(y/=x).or.len(y)/=len(x))stop 1
write(*,'(i0)')len(y)
end subroutine
end module
program p
use m
implicit none
call f('x')
call f('abcde')
call f('')
end program
