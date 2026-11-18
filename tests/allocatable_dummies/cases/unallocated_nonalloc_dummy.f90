module m

contains
subroutine see(a)
integer,intent(in)::a(:)
end subroutine
end module
program main
use m
integer,allocatable::v(:)
call see(v)
end program
