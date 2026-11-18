module m
implicit none
contains
subroutine setp(x,p)
integer,target,intent(out)::x(:)
integer,pointer,intent(out)::p(:)
p=>x
x(1)=4
end subroutine
end module
program main
use m
implicit none
integer,target::a(2)
integer,pointer::p(:)
a=9
call setp(a,p)
print *,p(2)
end program
