module m
contains
subroutine copy(v,y)
character(*),intent(in)::v(:)
character(*),allocatable,intent(out)::y(:)
allocate(y(size(v)))
y=v
end subroutine
end module
program main
use m
implicit none
character(2),allocatable::x(:)
allocate(x(3))
x=["ab","cd","ef"]
call copy((x([integer::])),x)
print "(i0)",size(x)
end program
