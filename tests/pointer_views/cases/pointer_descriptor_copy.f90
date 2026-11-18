module m
contains
subroutine copy(p,q)
integer,pointer,intent(in)::p(:)
integer,pointer,intent(out)::q(:)
q=>p
end subroutine
end module
program main
use m
integer,target::a(-1:0)
integer,pointer::p(:),q(:)
a=0
p=>a
call copy(p,q)
q(0)=7
if(a(0)/=7.or.p(0)/=7) error stop 1
if(lbound(q,1)/=-1.or.ubound(q,1)/=0) error stop 2
print *,1
end
