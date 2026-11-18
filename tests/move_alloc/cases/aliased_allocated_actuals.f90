program p
implicit none
integer,allocatable :: a(:)
allocate(a(1))
call q(a,a)
contains
subroutine q(x,y)
integer,allocatable,intent(inout) :: x(:),y(:)
call move_alloc(x,y)
end subroutine
end program
