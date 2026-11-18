module m
implicit none
contains
subroutine first()
contains
subroutine child()
end subroutine
end subroutine
subroutine second()
call child()
end subroutine
end module
program p
use m
implicit none
call second()
end program
