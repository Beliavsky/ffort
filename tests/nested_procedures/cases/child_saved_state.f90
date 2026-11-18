module m
implicit none
contains
subroutine host(answer)
integer,intent(out)::answer
answer=0
call child()
contains
subroutine child()
integer,save::x=10
x=x+1
answer=x
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::a,b
call host(a)
call host(b)
print *,a,b
end program
