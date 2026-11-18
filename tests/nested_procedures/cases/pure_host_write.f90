module m
implicit none
contains
pure subroutine host(answer)
integer,intent(out)::answer
answer=0
call child()
contains
pure subroutine child()
answer=1
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(answer)
end program
