module m
implicit none
contains
subroutine host()
integer::i
do i=1,3
call child()
end do
contains
subroutine child()
i=9
end subroutine
end subroutine
end module
program p
use m
implicit none
call host()
end program
