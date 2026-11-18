module m
implicit none
contains
subroutine host(answer)
integer,intent(out)::answer
integer::x
x=0
answer=child()
contains
integer function child() result(y)
call sibling()
y=x
end function
subroutine sibling()
x=x+1
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(answer)
end program
