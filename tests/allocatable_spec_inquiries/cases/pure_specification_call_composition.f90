module m
implicit none
contains
pure function twice(n) result(r)
integer,intent(in)::n
integer::r
r=2*n
end function
subroutine probe(a)
integer,allocatable,intent(inout)::a(:)
integer::v(twice(size(a)))
if(size(v)/=6) error stop 1
v=3
deallocate(a)
allocate(a(1))
if(size(v)/=6.or.sum(v)/=18) error stop 2
end subroutine
end module
program main
use m
integer,allocatable::data(:)
allocate(data(3))
call probe(data)
if(size(data)/=1) error stop 3
print *,1
end
