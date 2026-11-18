module m
implicit none
contains
recursive subroutine host(depth,answer)
integer,intent(in)::depth
integer,intent(out)::answer
integer::x
x=10*depth
call child()
answer=x
contains
recursive subroutine child()
integer::below
below=0
if(depth>0) call host(depth-1,below)
x=x+below
call sibling()
end subroutine
subroutine sibling()
x=x+1
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(3,answer)
print *,answer
call host(1,answer)
print *,answer
end program
