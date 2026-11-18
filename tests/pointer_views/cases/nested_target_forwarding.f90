module m
implicit none
contains
subroutine getcol(x,p)
integer,target,intent(inout)::x(:,:)
integer,pointer,intent(out)::p(:)
p=>x(:,2)
x(2,2)=7
end subroutine
subroutine outer(x,p)
integer,target,intent(inout)::x(:,:)
integer,pointer,intent(out)::p(:)
call getcol(x,p)
end subroutine
end module
program main
use m
implicit none
integer,target::a(2,2)
integer,pointer::p(:)
a=0
call outer(a,p)
p=6
if(any(a(:,2)/=[6,6])) error stop 1
print *,1
end program
