module m
contains
subroutine start(a,b)
integer,allocatable,intent(inout)::a(:),b(:)
allocate(a(1),b(2))
end subroutine
end module
program p
use m
integer,allocatable::x(:)
call start(x,x)
print *,size(x)
end program
