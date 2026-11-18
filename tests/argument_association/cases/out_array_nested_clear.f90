program main

implicit none
integer :: a(4)
a=1
call change(a)
print *,a(1)
print *,a(3)
contains
subroutine change(x)
integer, intent(inout) :: x(:)
call next(x(2:3))
end subroutine change
subroutine next(x)
integer, intent(out) :: x(:)
x(1)=3
end subroutine next
end program main
