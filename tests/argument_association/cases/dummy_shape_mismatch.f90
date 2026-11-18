program main

implicit none
integer :: a(3),b(2)
a=1
b=2
call change(a,b)
contains
subroutine change(x,y)
integer, intent(out) :: x(:)
integer, intent(in) :: y(:)
x=y
end subroutine change
end program main
