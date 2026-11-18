module m
implicit none
contains
subroutine host()
contains
subroutine child()
end subroutine
end subroutine
end module
program p
use m,only:child
call child()
end program
