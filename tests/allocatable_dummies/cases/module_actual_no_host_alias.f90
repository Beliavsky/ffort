module m
integer,allocatable::v(:)
contains
subroutine make(a,n)
integer,allocatable,intent(out)::a(:)
integer,intent(in)::n
if(allocated(a)) error stop 1
allocate(a(-2:n-3))
a=5
end subroutine
end module
program main
use m

call make(v,3)
print *,size(v),lbound(v,1),sum(v)
end program
