program main

implicit none
integer :: a(3)
a=7
call change(a)
print *,a(1)
print *,a(2)
contains
subroutine change(x)
integer, intent(out) :: x(:)
x(1)=4
end subroutine change
end program main
