! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(4)
integer,pointer::p(:)
a=1
p=>a
contains
subroutine edit(p,x,n)
integer,pointer,intent(in)::p(:)
integer,intent(in)::n
integer,intent(inout)::x(n)
x(1)=p(1)
end subroutine
end program
