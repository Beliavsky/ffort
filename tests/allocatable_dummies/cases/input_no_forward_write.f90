module m

contains
subroutine make(a,n)
integer,allocatable,intent(out)::a(:)
integer,intent(in)::n
if(allocated(a)) error stop 1
allocate(a(-2:n-3))
a=5
end subroutine
subroutine bad(a)
integer,allocatable,intent(in)::a(:)
call make(a,2)
end subroutine
end module
program main
use m
integer,allocatable::v(:)
call bad(v)
end program
