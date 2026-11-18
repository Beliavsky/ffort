module m
implicit none
contains
subroutine bad(p)
integer,pointer,intent(out)::p(:)
integer,target::a(2)
a=1
p=>a
end subroutine
end module
program main
use m
implicit none
integer,pointer::p(:)
call bad(p)
end program
