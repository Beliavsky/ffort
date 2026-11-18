program main

implicit none
integer :: a(3)
a=1
call change(a)
contains
subroutine change(x)
integer, intent(in) :: x(:)
call next(x(2:3))
end subroutine change
subroutine next(x)
integer, intent(inout) :: x(:)
x=2
end subroutine next
end program main
