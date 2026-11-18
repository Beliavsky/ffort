! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(6)
integer,pointer::p(:)
a=9
p=>a
call partial(a,3)
print *,p(2)
contains
subroutine partial(x,n)
integer,intent(in)::n
integer,target,intent(out)::x(n)
x(1)=10
x(3)=30
end subroutine
end program
