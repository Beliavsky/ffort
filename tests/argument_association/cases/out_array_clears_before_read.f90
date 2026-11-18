program main

implicit none
integer :: a(3)
a=7
call change(a)
contains
subroutine change(x)
integer, intent(out) :: x(:)
print *,x(2)
end subroutine change
end program main
