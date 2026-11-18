module m

contains
subroutine see(a)
integer,allocatable,intent(in)::a(:)
end subroutine
end module
program main
use m
integer,allocatable::v(:)
call see([1,2])
end program
