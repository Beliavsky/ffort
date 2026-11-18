module m
contains
subroutine bad(p)
integer,pointer,intent(inout),optional::p(:)
nullify(p)
end subroutine
end module
program main
use m
call bad()
end
