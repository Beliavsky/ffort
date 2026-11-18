module m
contains
subroutine f(x)
character(*),intent(in)::x(:)
integer::i
print *,size([x]),len([x]),size([(x,i=1,0)]),len([(x,i=1,0)])
end subroutine
end module
program p
use m
character(7)::x(0)
call f(x)
end program
