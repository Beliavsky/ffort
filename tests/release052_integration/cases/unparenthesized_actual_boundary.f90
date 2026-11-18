module move_mod
implicit none
contains
subroutine replace(src,dst)
character(*),intent(in)::src(:)
character(*),allocatable,intent(out)::dst(:)
allocate(dst(size(src)))
dst=src
end subroutine
end module
program main
use move_mod
implicit none
character(2),allocatable::x(:)
allocate(x(3))
x=['aa','bb','cc']
call replace(x([3,1,3]),x)
print '(3a2)',x
end program
