module m
implicit none
contains
subroutine probe(a)
integer,allocatable,intent(inout)::a(:)
integer::v(lbound(a,1))
print *,99
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:)
call probe(a)
end
