module m
implicit none
contains
subroutine host()
call child()
contains
recursive subroutine child()
call child()
end subroutine
end subroutine
end module
program p
use m
implicit none
call host()
end program
