! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,pointer::p(:)
call outer(p)
contains
subroutine outer(p)
integer,pointer,intent(out)::p(:)
integer,target::a(4)
a=7
call inner(a,p)
if(.not.associated(p)) error stop 1
end subroutine
subroutine inner(x,p)
integer,target,intent(in)::x(:)
integer,pointer,intent(out)::p(:)
p=>x(4:2:-1)
end subroutine
end program
