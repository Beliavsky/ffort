program main

implicit none
integer :: a(3)
a=1
call change(a(1:4))
contains
subroutine change(x)
integer, intent(inout) :: x(:)
x=3
end subroutine change
end program main
