! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(4)
a=0
call missing(a,2)
contains
subroutine missing(x,n,p)
integer,intent(in)::n
integer,target,intent(inout)::x(n)
integer,pointer,intent(out),optional::p(:)
nullify(p)
end subroutine
end program
