program p
implicit none
integer,allocatable :: a(:),b(:)
allocate(a(2));a=7
call q(a,b)
if(allocated(a).or.any(b/=7)) error stop 1
contains
subroutine q(x,y)
integer,allocatable,optional,intent(inout) :: x(:)
integer,allocatable,intent(inout) :: y(:)
if(present(x))call move_alloc(x,y)
end subroutine
end program
