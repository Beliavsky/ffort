program p
implicit none
integer,allocatable :: a(:),b(:)
allocate(a(-1:1));a=[4,5,6]
call first(a,b)
if(allocated(a).or.any(b/=[4,5,6]).or.lbound(b,1)/=-1) error stop 1
contains
subroutine first(x,y)
integer,allocatable,intent(inout) :: x(:),y(:)
call second(x,y)
end subroutine
subroutine second(x,y)
integer,allocatable,intent(inout) :: x(:),y(:)
call move_alloc(x,y)
end subroutine
end program
