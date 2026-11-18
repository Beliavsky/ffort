module m
implicit none
contains
subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
call child()
contains
subroutine child()
integer::a(n)
a=n
answer=sum(a)
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(4,answer)
print *,answer
end program
