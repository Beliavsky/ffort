module m
implicit none
contains
recursive subroutine tick(depth,x)
integer,intent(in)::depth,x
integer,save::n=0
n=n+1
if(depth>0) call tick(depth-1,(n))
print *,depth,x,n
end subroutine
end module
program p
use m
implicit none
call tick(2,0)
end program
