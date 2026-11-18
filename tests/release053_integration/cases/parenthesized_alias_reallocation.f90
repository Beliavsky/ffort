module m
implicit none
contains
subroutine replace(a,b)
integer,intent(in)::a(:)
integer,allocatable,intent(out)::b(:)
allocate(b(size(a)))
b=a
end subroutine
end module
program p
use m
implicit none
integer,allocatable::x(:)
x=[2,4,6]
call replace((x([3,1,3])),x)
write(*,'(3i3)')x
end program
