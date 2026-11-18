module m
contains
subroutine f(x,z)
character(*),intent(in)::x,z
character(len(x))::a(3)
integer::i
a=[x,(z,i=1,2)]
if(any(a/="abc"))stop 1
print "(a)","OK"
end subroutine
end module
program p
use m
call f("abc","abc")
end program
