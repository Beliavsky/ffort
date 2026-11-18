module m
implicit none
contains
subroutine probe(a,d)
integer,allocatable,intent(in)::a(:)
integer,intent(in)::d
integer::v(size(a,d))
print *,99
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:)
allocate(a(2))
call probe(a,2)
end
