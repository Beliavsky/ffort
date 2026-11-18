! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(8)
integer,pointer::p(:)
a=[1,2,3,4,5,6,7,8]
p=>a(8:2:-2)
call update(a(8:2:-2),2)
print *,a,p,findloc(p,60),shape(p)
contains
subroutine update(x,n)
integer,intent(in)::n
integer,target,intent(out)::x(-1:n-2)
x=[80,60]
end subroutine
end program
