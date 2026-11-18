program main

implicit none
integer :: a(100)
print *,99
call change(a)
contains
subroutine change(x)
integer, intent(out) :: x(:)
x=3
end subroutine change
end program main
