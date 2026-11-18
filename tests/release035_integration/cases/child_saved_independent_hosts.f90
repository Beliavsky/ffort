module composition
implicit none
contains
subroutine first(answer)
integer,intent(out)::answer
integer::state
state=100
call char()
contains
subroutine char()
integer,save::visits=0
visits=visits+1
state=state+visits
answer=state
end subroutine
end subroutine
subroutine second(answer)
integer,intent(out)::answer
integer::state
state=200
call char()
contains
subroutine char()
integer,save::visits=10
visits=visits+1
state=state+visits
answer=state
end subroutine
end subroutine
end module
program main
use composition
implicit none
integer::a,b,c,d
call first(a)
call second(b)
call first(c)
call second(d)
write(*,'("saved:",4(1x,i0))')a,b,c,d
end program
