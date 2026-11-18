module m
implicit none
contains
subroutine host(a,answer)
integer,intent(inout)::a(-2:)
integer,intent(out)::answer
integer::local(-1:1)
local=[1,2,3]
call child()
answer=sum(local)
contains
subroutine child()
a(-2)=a(-2)+10
a(-1:0)=a(-1:0)+local(0:1)
local(-1)=a(0)
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::a(5),answer
a=[1,2,3,4,5]
call host(a(2:4),answer)
print *,a,answer
end program
