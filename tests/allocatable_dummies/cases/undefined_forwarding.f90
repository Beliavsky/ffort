module m

contains
subroutine make(a)
integer,allocatable,intent(out)::a(:)
allocate(a(2))
a(1)=5
end subroutine
subroutine finish(a)
integer,allocatable,intent(inout)::a(:)
a(2)=7
end subroutine
end module
program main
use m
integer,allocatable::v(:)
call make(v)
call finish(v)
print *,v
end program
