module m
implicit none
contains
subroutine host(x)
integer,intent(in)::x
call child()
contains
subroutine child()
x=1
end subroutine
end subroutine
end module
program p
use m
implicit none
call host(0)
end program
