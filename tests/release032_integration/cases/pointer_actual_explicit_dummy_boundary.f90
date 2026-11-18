! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(4)
integer,pointer::p(:)
a=1
p=>a
call edit(p,2)
contains
subroutine edit(x,n)
integer,intent(in)::n
integer,target,intent(inout)::x(n)
x=2
end subroutine
end program
