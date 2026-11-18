module m
implicit none
contains
subroutine probe(a)
character(:),allocatable,intent(inout)::a(:,:)
logical::v(size(a,1),size(a,2))
v=.true.
if(size(v)/=6.or..not.all(v)) error stop 1
deallocate(a)
allocate(character(2)::a(1,1))
end subroutine
end module
program main
use m
implicit none
character(:),allocatable::a(:,:)
allocate(character(7)::a(2,3))
call probe(a)
if(len(a)/=2.or.size(a)/=1) error stop 2
print *,1
end
