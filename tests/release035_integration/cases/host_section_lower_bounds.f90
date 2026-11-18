module composition
implicit none
contains
subroutine host(a)
integer,intent(inout)::a(-2:)
integer::local(-1:1)
local=[10,20,30]
call child()
call finish()
contains
subroutine child()
a(-2:0)=a(-2:0)+local
local=local+1
end subroutine
subroutine finish()
a(0)=a(0)+sum(local)
end subroutine
end subroutine
end module
program main
use composition
implicit none
integer::a(5)
a=[1,2,3,4,5]
call host(a(2:4))
write(*,'("section:",5(1x,i0))')a
end program
