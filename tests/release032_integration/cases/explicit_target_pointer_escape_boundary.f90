! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(6)
integer,pointer::p(:)
a=4
call expose(a,3,p)
contains
subroutine expose(x,n,p)
integer,intent(in)::n
integer,target,intent(inout)::x(n)
integer,pointer,intent(out)::p(:)
p=>x
end subroutine
end program
