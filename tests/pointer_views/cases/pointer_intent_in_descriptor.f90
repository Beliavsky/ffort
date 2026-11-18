module m
implicit none
contains
subroutine inspect(p)
integer,pointer,intent(in)::p(:)
if(.not.associated(p)) error stop 1
end subroutine
end module
program main
use m
implicit none
integer,target::a(2)
integer,pointer::p(:)
p=>a
call inspect(p)
p=4
if(any(a/=[4,4])) error stop 2
print *,1
end program
