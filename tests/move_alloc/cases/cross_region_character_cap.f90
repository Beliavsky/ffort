module m
implicit none
character(65536),allocatable :: a(:)
contains
subroutine q()
character(65536),allocatable :: b(:),c(:)
allocate(b(1),c(128))
call move_alloc(a,b)
end subroutine
end module
program p
use m
implicit none
allocate(a(129))
call q()
end program
