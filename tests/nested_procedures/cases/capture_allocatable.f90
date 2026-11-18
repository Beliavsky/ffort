module m
implicit none
contains
subroutine host()
integer,allocatable::a(:)
allocate(a(2))
a=1
call child()
contains
subroutine child()
a=a+1
end subroutine
end subroutine
end module
program p
use m
implicit none
call host()
end program
