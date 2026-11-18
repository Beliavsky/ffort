module m
implicit none
contains
subroutine host(answer)
integer,intent(out)::answer
integer::x,y
x=7
y=20
call child(y)
answer=x+y
contains
subroutine child(x)
integer,intent(inout)::x
x=x+2
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(answer)
print *,answer
end program
