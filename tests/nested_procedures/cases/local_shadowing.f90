module m
implicit none
contains
subroutine host(answer)
integer,intent(out)::answer
integer::x
x=7
call first()
call second()
answer=x
contains
subroutine first()
integer::x
x=100
call second()
print *,x
end subroutine
subroutine second()
x=x+1
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
