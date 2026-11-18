module m
contains
subroutine bad(p)
integer,pointer,intent(out),optional::p(:)
integer,target::a(2)
p=>a
end subroutine
end module
program main
use m
call bad()
end
