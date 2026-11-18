module m
implicit none
integer,allocatable :: a(:)
contains
subroutine initialize()
allocate(a(-2:0))
a=[1,2,3]
end subroutine
subroutine grow()
a=[a,4]
end subroutine
end module
program probe
use m
implicit none
call initialize()
call grow()
print *,lbound(a,1),ubound(a,1),a
end program
