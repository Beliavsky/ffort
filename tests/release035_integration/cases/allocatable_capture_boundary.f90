module composition
implicit none
contains
subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
integer,allocatable::a(:)
allocate(a(2))
a=3
call child()
contains
subroutine child()
answer=sum(a)
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
