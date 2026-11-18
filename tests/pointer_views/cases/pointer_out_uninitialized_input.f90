module m
implicit none
contains
subroutine setp(x,p)
integer,target,intent(in)::x(:)
integer,pointer,intent(out)::p(:)
p=>x
end subroutine
end module
program main
use m
implicit none
integer,target::a(2)
integer,pointer::p(:)
a=[4,5]
call setp(a,p)
if(any(p/=[4,5])) error stop 1
print *,1
end program
