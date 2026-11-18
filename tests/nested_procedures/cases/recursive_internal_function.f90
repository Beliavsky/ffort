module m
implicit none
contains
subroutine host(base,n,answer)
integer,intent(in)::base,n
integer,intent(out)::answer
answer=total(n)
contains
recursive integer function total(k) result(y)
integer,intent(in)::k
if(k==0) then
y=base
else
y=k+total(k-1)
end if
end function
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(10,5,answer)
print *,answer
end program
