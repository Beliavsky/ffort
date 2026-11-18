program main

implicit none
integer :: a(5)
a=7
call change(a(1:5:2))
print *,a(2),a(4),a(1)
print *,a(3)
contains
subroutine change(x)
integer, intent(out) :: x(:)
x(1)=4
end subroutine change
end program main
