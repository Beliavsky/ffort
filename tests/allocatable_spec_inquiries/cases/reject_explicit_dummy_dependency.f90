module m
implicit none
contains
subroutine probe(a,b)
integer,allocatable,intent(in)::a(:)
integer,intent(out)::b(size(a))
b=0
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:)
integer::b(2)
allocate(a(2))
call probe(a,b)
end
