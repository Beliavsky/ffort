module m
implicit none
contains
subroutine get(p)
integer,pointer,intent(in)::p(:)
print *,p(1)
end subroutine
end module
program main
use m
implicit none


end program
