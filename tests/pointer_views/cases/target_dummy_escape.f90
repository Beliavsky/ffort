module m
implicit none
contains
subroutine getcol(x,p)
integer,target,intent(inout)::x(:,:)
integer,pointer,intent(out)::p(:)
p=>x(:,2)
x(2,2)=7
end subroutine
end module
program main
use m
implicit none
integer,target::a(2,2)
integer,pointer::p(:)
a=0
a(:,2)=[3,4]
call getcol(a,p)
if(any(p/=[3,7])) error stop 1
p(1)=9
if(a(1,2)/=9) error stop 2
a(2,2)=8
if(p(2)/=8) error stop 3
print *,1
end program
