module m

contains
subroutine make(a)
integer,allocatable,intent(out)::a(:)
allocate(a(2))
a(1)=2
end subroutine
end module
program main
use m
integer,allocatable::v(:)
call make(v)
print *,v(2)
end program
