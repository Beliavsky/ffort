program main

implicit none
real :: a(3)
a=1.25
call change(a)
print *,a
contains
subroutine change(x)
real, intent(inout) :: x(:)
x=x+0.5
end subroutine change
end program main
