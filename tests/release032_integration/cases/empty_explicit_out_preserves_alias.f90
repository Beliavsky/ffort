! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(4)
integer,pointer::p(:)
a=[10,20,30,40]
p=>a
call wipe(a,0)
print *,p,shape(p),findloc(p,30)
contains
subroutine wipe(x,n)
integer,intent(in)::n
integer,target,intent(out)::x(-2:n-3)
if(size(x)/=0) error stop 1
x=7
end subroutine
end program
