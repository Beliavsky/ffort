module composition
implicit none
contains
subroutine host(answer)
integer,intent(out)::answer
integer::state
state=1
answer=peek()
contains
pure integer function peek() result(x)
call mutate()
x=state
end function
subroutine mutate()
state=state+1
end subroutine
end subroutine
end module
program main
use composition
implicit none
integer::answer
call host(answer)
end program
