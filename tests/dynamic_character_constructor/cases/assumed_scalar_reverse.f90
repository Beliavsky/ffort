module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i,j
character(len(x))::y(3)
y=[(x,i=3,1,-1)]
if(any(y/=x))stop 1
print '(a)','OK'
end subroutine
end module
program p
use m
implicit none
call f('abc')
end program
