module m
implicit none
contains
subroutine host(x)
integer,intent(in),optional::x
call child()
contains
subroutine child()
if(present(x)) print *,x
end subroutine
end subroutine
end module
program p
use m
implicit none
call host(1)
end program
