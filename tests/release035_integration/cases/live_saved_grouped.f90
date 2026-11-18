module live_composition
implicit none
contains
subroutine host(n,a)
integer,intent(in)::n
integer,intent(inout)::a(:)
integer,save::calls=0
integer::state
character(5)::char
state=n
char='a b  '
calls=calls+1
call descend(n)
write(*,'("frame",2(1x,i0)," [",a,"]")')calls,state,char
write(*,'("array",2(1x,i0))')a
contains
recursive subroutine descend(k)
integer,intent(in)::k
integer::local
local=k
if(k>0)call descend(k-1)
state=state+local
a=a+local
call sibling()
end subroutine
subroutine sibling()
char='x y  '
state=state+1
end subroutine
end subroutine
end module
program main
use live_composition
implicit none
integer::a(2)
a=[1,2]
call host(2,a)
call host(1,a)
end program
