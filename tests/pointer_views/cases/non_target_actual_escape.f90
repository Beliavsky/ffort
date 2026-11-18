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
integer::a(2,2)
integer,pointer::p(:)
a=0
call getcol(a,p)
end program
