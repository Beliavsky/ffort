module m

contains
subroutine make(a,n)
integer,allocatable,intent(out)::a(:)
integer,intent(in)::n
if(allocated(a)) error stop 1
allocate(a(-2:n-3))
a=5
end subroutine
subroutine forward(a,n)
integer,allocatable,intent(inout)::a(:)
integer,intent(in)::n
call make(a,n)
end subroutine
end module
program main
use m
integer,allocatable::v(:)
call forward(v,4)
print *,size(v),lbound(v,1),sum(v)
end program
