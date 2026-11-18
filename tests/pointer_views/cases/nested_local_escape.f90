module m
contains
subroutine inner(x,p)
integer,target,intent(in)::x(:)
integer,pointer,intent(out)::p(:)
p=>x
end subroutine
subroutine outer(p)
integer,pointer,intent(out)::p(:)
integer,target::a(2)
a=4
call inner(a,p)
if(.not.associated(p)) error stop 1
end subroutine
end module
program main
use m
integer,pointer::p(:)
call outer(p)
end
