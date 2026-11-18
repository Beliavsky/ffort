module composition
implicit none
contains
subroutine host()
character(32769)::a
a=repeat('x',32769)
call child()
contains
subroutine child()
write(*,*)a,a
end subroutine
end subroutine
end module
program main
use composition
implicit none
call host()
end program
