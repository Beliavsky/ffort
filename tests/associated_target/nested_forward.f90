module m
contains
subroutine outer(x,p)
integer,target,intent(in)::x(:)
integer,pointer,intent(in)::p(:)
call inner(x,p)
end subroutine
subroutine inner(x,p)
integer,target,intent(in)::x(:)
integer,pointer,intent(in)::p(:)
print *,associated(p,x)
end subroutine
end module
program main
use m
implicit none
integer,target::a(3)
integer,pointer::p(:)
p=>a
call outer(a,p)
end program
