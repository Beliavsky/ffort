module m
implicit none
contains
subroutine consume(v)
character(*),intent(in)::v(:)
print "(a)",v
end subroutine
end module
program main
use m
implicit none
character(:),allocatable::x(:)
allocate(character(2)::x(3))
x=["ab","cd","ef"]
call consume(x([3,1]))
end program
