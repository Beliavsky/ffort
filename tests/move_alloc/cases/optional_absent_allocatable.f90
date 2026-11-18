program p
implicit none
integer,allocatable :: b(:)
call q(y=b)
contains
subroutine q(x,y)
integer,allocatable,optional,intent(inout) :: x(:)
integer,allocatable,intent(inout) :: y(:)
call move_alloc(x,y)
end subroutine
end program
