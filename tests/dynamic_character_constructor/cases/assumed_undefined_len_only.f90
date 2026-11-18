module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i
if(len([(x,i=1,3)])/=7)stop 1
print '(a)','OK'
end subroutine
end module
program p
use m
implicit none
character(7)::a
call f(a)
end program
