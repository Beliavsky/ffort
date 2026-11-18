module m
implicit none
contains
subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
integer::a(n)
a=0
call child()
answer=sum(a)
contains
subroutine child()
a=a+1
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(0,answer)
print *,answer
call host(3,answer)
print *,answer
end program
