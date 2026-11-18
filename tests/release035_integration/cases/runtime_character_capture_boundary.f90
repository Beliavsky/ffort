module composition
implicit none
contains
subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
character(n)::a
a='xx'
call child()
contains
subroutine child()
answer=len(a)
end subroutine
end subroutine
end module
program main
use composition
implicit none
integer::answer
call host(2,answer)
write(*,'(i0)')answer
end program
