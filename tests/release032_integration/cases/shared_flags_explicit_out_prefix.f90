! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(6)
integer,pointer::p(:),q(:)
a(4:6)=[40,50,60]
p=>a
q=>p
call relay(a)
print *,p(1),q(3),p(4:6)
q(2)=20
print *,a,findloc(p,90)
contains
subroutine relay(x)
integer,target,intent(inout)::x(:)
call partial(x,3)
end subroutine
subroutine partial(x,n)
integer,intent(in)::n
integer,target,intent(out)::x(n)
x(1)=30
x(3)=90
end subroutine
end program
