module m
implicit none
contains
subroutine bad(p,q)
integer,pointer,intent(inout)::p(:),q(:)
nullify(p)
nullify(q)
end subroutine
end module
program main
use m
implicit none
integer,pointer::p(:)
nullify(p)
call bad(p,p)
end program
