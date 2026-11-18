module composition
implicit none
contains
subroutine host(answer)
integer,intent(out)::answer
integer::state
state=3
call child(state)
contains
subroutine child(x)
integer,intent(in)::x
answer=state+x
end subroutine
end subroutine
end module
program main
use composition
implicit none
integer::answer
call host(answer)
end program
