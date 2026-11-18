module m
contains
subroutine bad(p)
integer,pointer,intent(in),optional::p(:)
integer,pointer::q(:)
q=>p
end subroutine
end module
program main
use m
call bad()
end
