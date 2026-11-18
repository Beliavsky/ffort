module m
implicit none
contains
subroutine host()
integer,target::x
x=1
call child()
contains
subroutine child()
x=x+1
end subroutine
end subroutine
end module
program p
use m
implicit none
call host()
end program
