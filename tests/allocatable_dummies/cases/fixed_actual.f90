module m

contains
subroutine see(a)
integer,allocatable,intent(in)::a(:)
end subroutine
end module
program main
use m
integer::v(3)
call see(v)
end program
