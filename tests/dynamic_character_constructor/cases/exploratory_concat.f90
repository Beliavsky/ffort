module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x(:)
integer::i
character(4)::a(2)
a=[(x(1)//x(2),i=1,2)]
print "(a)","OK"
end subroutine
end module
program p
use m
implicit none
call f(["ab","cd"])
end program
