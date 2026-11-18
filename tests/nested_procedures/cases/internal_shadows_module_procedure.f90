module m
implicit none
contains
subroutine increment(x)
integer,intent(inout)::x
x=x+1000
end subroutine
subroutine host(answer)
integer,intent(out)::answer
integer::x
x=1
call increment()
answer=x
contains
subroutine increment()
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
