module m
contains
subroutine bad(p)
integer,pointer,intent(in),optional::p(:)
if(associated(p)) stop
end subroutine
end module
program main
use m
call bad()
end
