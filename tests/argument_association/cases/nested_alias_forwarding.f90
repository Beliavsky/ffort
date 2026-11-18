program main

implicit none
integer :: a(4)
a=1
call change(a)
contains
subroutine change(x)
integer, intent(inout) :: x(:)
call next(x(1:3),x(2:4))
end subroutine change
subroutine next(x,y)
integer, intent(out) :: x(:),y(:)
return
end subroutine next
end program main
