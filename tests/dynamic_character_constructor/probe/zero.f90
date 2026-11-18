module m
contains
subroutine f(x,n)
character(*),intent(in)::x
integer,intent(in)::n
integer::i
print *,size([(x,i=1,n)]),len([(x,i=1,n)])
end subroutine
end module
program p
use m
character(7)::x
call f(x,0)
end program
