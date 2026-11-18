module m
contains
subroutine inspect(x,p)
integer,target,intent(out)::x(:)
integer,pointer,intent(in)::p(:)
print *,associated(p,x)
end subroutine
end module
program main
use m
implicit none
integer,target::a(4)
integer,pointer::p(:)
p=>a
call inspect(a,p)
end program
