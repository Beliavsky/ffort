module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x(:)
integer::i
character(len(x))::y(2*size(x))
y=[(x,i=1,2)]
if(size(y)/=4.or.len(y)/=0)stop 1
print '(a)','OK'
end subroutine
end module
program p
use m
implicit none
character(0)::a(2)
a=''
call f(a)
end program
