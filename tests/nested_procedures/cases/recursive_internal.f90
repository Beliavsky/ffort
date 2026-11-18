module m
implicit none
contains
subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
integer::total
total=0
call descend(n)
answer=total
contains
recursive subroutine descend(k)
integer,intent(in)::k
integer::saved
saved=k
if(k>0) call descend(k-1)
total=total+saved
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(5,answer)
print *,answer
call host(3,answer)
print *,answer
end program
