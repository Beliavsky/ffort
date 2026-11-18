module m
implicit none
contains
subroutine inspect(p)
integer,pointer,intent(in),optional::p(:)
if(present(p)) then
if(associated(p)) error stop 1
end if
end subroutine
end module
program main
use m
implicit none
integer,pointer::p(:)
nullify(p)
call inspect(p)
call inspect()
print *,1
end program
