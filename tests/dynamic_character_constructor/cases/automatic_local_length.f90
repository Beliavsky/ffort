module m
contains
subroutine f(n)
integer,intent(in)::n
character(n)::x,y(2)
integer::i
x=repeat("Q",n)
y=[(x,i=1,2)]
if(any(y/=x).or.len(y)/=n)stop 1
print "(a)","OK"
end subroutine
end module
program p
use m
call f(4)
end program
