module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i
if(size([(x,i=1,0)])/=0.or.len([(x,i=1,0)])/=len(x))stop 1
print '(a)','OK'
end subroutine
end module
program p
use m
implicit none
call f('abc')
end program
