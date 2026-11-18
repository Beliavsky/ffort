module m
implicit none
contains
subroutine host()
integer::x
x=7
call child(x)
contains
subroutine child(y)
integer,intent(inout)::y
y=y+1
x=x+1
end subroutine
end subroutine
end module
program p
use m
implicit none
call host()
end program
