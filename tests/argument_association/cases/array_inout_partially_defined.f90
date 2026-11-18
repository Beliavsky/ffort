program main

implicit none
integer :: a(5)
a(3)=6
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(inout) :: x(:)
x=x(3)
end subroutine change
end program main
