module m
implicit none
contains
subroutine host(answer)
integer,intent(out)::answer
integer,save::x=10
call child()
answer=x
contains
subroutine child()
x=x+1
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
