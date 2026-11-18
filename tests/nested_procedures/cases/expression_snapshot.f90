module m
implicit none
contains
subroutine host(answer)
integer,intent(out)::answer
integer::x
x=7
call child((x))
answer=x
contains
subroutine child(y)
integer,intent(in)::y
x=100+y
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
