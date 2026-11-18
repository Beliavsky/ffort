module m
contains
subroutine inspect(x,p)
integer,target,optional,intent(in)::x(:)
integer,pointer,optional,intent(in)::p(:)
print *,associated(p,x)
end subroutine
end module
program main
use m
implicit none
integer,target::a(4)
integer,pointer::p(:)
p=>a
call inspect(a)
end program
