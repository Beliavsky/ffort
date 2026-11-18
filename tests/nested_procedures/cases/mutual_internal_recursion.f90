module m
implicit none
contains
subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
integer::total
total=0
call first(n)
answer=total
contains
recursive subroutine first(k)
integer,intent(in)::k
total=total+1
if(k>0) call second(k-1)
end subroutine
recursive subroutine second(k)
integer,intent(in)::k
total=total+10
if(k>0) call first(k-1)
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(4,answer)
print *,answer
call host(3,answer)
print *,answer
end program
