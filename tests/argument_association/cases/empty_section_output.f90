program main

implicit none
integer :: a(5)
a=3
call change(a(4:2))
print *,a
contains
subroutine change(x)
integer, intent(out) :: x(:)
x=7
end subroutine change
end program main
