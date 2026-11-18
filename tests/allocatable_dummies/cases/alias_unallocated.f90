module m

contains
subroutine pair(a,b)
integer,allocatable,intent(inout)::a(:),b(:)
a=[1]
b=[2]
end subroutine
end module
program main
use m
integer,allocatable::v(:)
call pair(v,v)
end program
