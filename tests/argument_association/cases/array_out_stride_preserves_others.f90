program main

implicit none
integer :: a(5)
a=9
call change(a(1:5:2))
print *,a
contains
subroutine change(x)
integer, intent(out) :: x(:)
x=4
end subroutine change
end program main
