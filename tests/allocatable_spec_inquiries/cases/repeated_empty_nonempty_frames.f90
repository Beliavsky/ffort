module m
implicit none
contains
subroutine probe(a,n)
integer,allocatable,intent(inout)::a(:)
integer,intent(in)::n
integer::v(size(a))
if(size(v)/=n) error stop 1
v=0
deallocate(a)
allocate(a(n+1))
end subroutine
end module
program main
use m
implicit none
integer,allocatable::data(:)
integer::i
allocate(data(0))
do i=0,4
call probe(data,i)
end do
if(size(data)/=5) error stop 2
print *,1
end
