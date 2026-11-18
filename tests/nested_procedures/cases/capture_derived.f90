module m
implicit none
type :: box
integer::x
end type
contains
subroutine host()
type(box)::a
a%x=1
call child()
contains
subroutine child()
a%x=a%x+1
end subroutine
end subroutine
end module
program p
use m
call host()
end program
