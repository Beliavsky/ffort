module composition
implicit none
contains
subroutine host()
character(65536)::a(256)
a=repeat('x',65536)
write(*,'(a)')'before list child'
call child()
contains
subroutine child()
write(*,*)a
end subroutine
end subroutine
end module
program main
use composition
implicit none
call host()
end program
