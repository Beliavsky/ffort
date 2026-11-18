module m
contains
subroutine f(x)
character(*),optional,intent(in)::x
integer::i
print *,len([(x,i=1,0)])
end subroutine
end module
program p
use m
call f()
end program
