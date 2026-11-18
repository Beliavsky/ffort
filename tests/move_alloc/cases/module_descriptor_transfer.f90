module m
implicit none
integer,allocatable :: a(:)
contains
subroutine transfer()
integer,allocatable :: b(:)
call move_alloc(a,b)
if(allocated(a).or.any(b/=[2,4,6])) error stop 1
call move_alloc(b,a)
if(allocated(b).or.lbound(a,1)/=-1) error stop 2
end subroutine
end module
program p
use m
implicit none
allocate(a(-1:1));a=[2,4,6]
call transfer()
if(any(a/=[2,4,6])) error stop 3
end program
