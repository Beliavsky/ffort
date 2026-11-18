module m
implicit none
contains
subroutine probe(a)
real(8),allocatable,intent(inout)::a(:,:)
logical::mask(size(a,1))
if(size(mask)/=3) error stop 1
mask=.true.
deallocate(a)
allocate(a(1,2))
a=4.0_8
if(size(mask)/=3.or..not.all(mask)) error stop 2
end subroutine
end module
program main
use m
implicit none
real(8),allocatable::a(:,:)
allocate(a(3,2))

call probe(a)
if(size(a,1)/=1.or.any(a/=4.0_8)) error stop 3
print *,1
end
