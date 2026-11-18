module m
implicit none
contains
subroutine host()
call child()
contains
subroutine child()
call grandchild()
contains
subroutine grandchild()
end subroutine
end subroutine
end subroutine
end module
program p
use m
implicit none
call host()
end program
