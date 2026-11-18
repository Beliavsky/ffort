module m

contains
subroutine grow(a)
integer,allocatable,intent(inout)::a(:)
a=[a,9]
end subroutine
end module
program main
use m
integer,allocatable::v(:)
allocate(v(-1:0))
v=[3,4]
call grow(v)
print *,v,lbound(v,1),ubound(v,1)
end program
