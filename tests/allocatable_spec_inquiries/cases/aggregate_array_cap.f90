module m
implicit none
contains
subroutine probe(a)
integer,allocatable,intent(in)::a(:)
logical::v(size(a))
print *,99
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:)
allocate(a(500001))
call probe(a)
end
