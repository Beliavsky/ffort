! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(-2:3)
integer,pointer::p(:),q(:)
a=[1,2,3,4,5,6]
p=>a
q=>p
call update(a,3)
print *,p,q(3),findloc(p,13),shape(p)
p(3)=60
print *,a
contains
subroutine update(x,n)
integer,intent(in)::n
integer,target,intent(inout)::x(0:n-1)
where(mod(x,2)==1) x=x+10
end subroutine
end program
