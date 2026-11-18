module m
implicit none
contains
subroutine clear(p)
integer,pointer,intent(out)::p(:)
integer,target::a(2)
p=>a
nullify(p)
end subroutine
end module
program main
use m
implicit none
integer,pointer::p(:)
call clear(p)
if(associated(p)) error stop 1
print *,1
end program
