! Synthetic release 0.33 composition fixture; original bodies, if any, are separate.
module m
implicit none
contains
pure integer function span(n) result(v)
integer,intent(in)::n
v=n+1
end function
recursive subroutine visit(depth,previous)
integer,intent(in)::depth,previous
integer::a(span(depth))
integer::counter=0
counter=counter+1
a=previous
if(depth>0) call visit(depth-1,counter)
print *,sum(a)
end subroutine
end module
program main
use m
implicit none
call visit(1,0)
end program
