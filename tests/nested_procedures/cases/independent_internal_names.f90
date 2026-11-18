module m
implicit none
contains
subroutine first(answer)
integer,intent(out)::answer
integer::x
x=10
call child()
answer=x
contains
subroutine child()
x=x+1
end subroutine
end subroutine
subroutine second(answer)
integer,intent(out)::answer
integer::x
x=100
call child()
answer=x
contains
subroutine child()
x=x+2
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::x,y
call first(x)
call second(y)
print *,x,y
call first(x)
print *,x
end program
