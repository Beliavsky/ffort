module m
implicit none
contains
subroutine bad(p)
integer,pointer,intent(out)::p(:)
if(associated(p)) stop
end subroutine
end module
program main
use m
implicit none
integer,target::a(2)
integer,pointer::p(:)
p=>a
call bad(p)
end program
