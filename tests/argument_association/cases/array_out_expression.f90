program main

implicit none
integer :: a(3)
a=1
call change(a+1)
contains
subroutine change(x)
integer, intent(out) :: x(:)
x=2
end subroutine change
end program main
