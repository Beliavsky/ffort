program main

implicit none
integer :: a(3)
a=1
call change(a)
contains
subroutine change(x)
integer, intent(inout) :: x(:)
x(0)=3
end subroutine change
end program main
