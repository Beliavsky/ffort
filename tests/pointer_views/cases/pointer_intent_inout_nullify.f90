module m
implicit none
contains
subroutine clear(p)
integer,pointer,intent(inout)::p(:)
if(.not.associated(p)) error stop 1
nullify(p)
end subroutine
end module
program main
use m
implicit none
integer,target::a(2)
integer,pointer::p(:),q(:)
a=[1,2]
p=>a
q=>p
call clear(p)
if(associated(p)) error stop 2
q(1)=9
if(a(1)/=9) error stop 3
print *,1
end program
