module m

contains
subroutine bad(a)
integer,allocatable,intent(in)::a(:)
a=[1,2]
end subroutine
end module
program main
use m
integer,allocatable::v(:)
call bad(v)
end program
