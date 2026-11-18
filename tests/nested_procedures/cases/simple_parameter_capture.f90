module m
implicit none
contains
subroutine host(answer)
integer,intent(out)::answer
integer,parameter::offset=7
answer=child(3)
contains
simple integer function child(x) result(y)
integer,intent(in)::x
y=x+offset
end function
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(answer)
print *,answer
end program
