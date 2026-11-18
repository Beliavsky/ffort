program main

implicit none
integer :: a(3),s
a=1
s=0
call change(a(1:3:s))
contains
subroutine change(x)
integer, intent(inout) :: x(:)
x=3
end subroutine change
end program main
