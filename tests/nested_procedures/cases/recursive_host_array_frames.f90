module m
implicit none
contains
recursive subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
integer::a(n)
a=n
call child()
answer=sum(a)
contains
recursive subroutine child()
integer::below
below=0
if(n>1) call host(n-1,below)
a(1)=a(1)+below
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(4,answer)
print *,answer
call host(2,answer)
print *,answer
end program
