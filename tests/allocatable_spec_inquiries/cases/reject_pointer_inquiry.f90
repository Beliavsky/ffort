module m
implicit none
contains
subroutine probe(a)
integer,pointer,intent(in)::a(:)
integer::v(size(a))
v=0
end subroutine
end module
program main
use m
implicit none
integer,target::x(2)
integer,pointer::a(:)
a=>x
call probe(a)
end
