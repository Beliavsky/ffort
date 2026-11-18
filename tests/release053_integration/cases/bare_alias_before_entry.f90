module m
implicit none
contains
subroutine replace(a,b)
integer,intent(in)::a(:)
integer,allocatable,intent(out)::b(:)
write(*,'(a)')'entered'
allocate(b(size(a)))
b=a
end subroutine
end module
program p
use m
implicit none
integer,allocatable::x(:)
x=[2,4,6]
write(*,'(a)')'before'
call replace(x([3,1]),x)
end program
