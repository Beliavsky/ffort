program p
implicit none
character(3),allocatable :: a(:),b(:)
allocate(a(2));a='abc'
call q(a,b)
if(allocated(a).or.any(b/='abc').or.len(a)/=3) error stop 1
contains
subroutine q(x,y)
character(3),allocatable,intent(inout) :: x(:),y(:)
call move_alloc(x,y)
if(allocated(x).or.len(x)/=3) error stop 2
end subroutine
end program
