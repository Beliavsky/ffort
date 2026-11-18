module m

contains
subroutine make(a)
integer,allocatable,intent(out)::a(:)
allocate(a(500001))
end subroutine
end module
program main
use m
integer,allocatable::v(:)
integer::fixed(500001)
call make(v)
end program
