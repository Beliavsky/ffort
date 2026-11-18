module m
contains
subroutine bump(a)
integer,intent(inout)::a(:)
a=a+3
end subroutine
end module
program main
use m
integer,allocatable::a(:)
allocate(a(-1:1))
a=[2,4,6]
call bump(a)
print *,a,lbound(a,1),ubound(a,1)
end program
