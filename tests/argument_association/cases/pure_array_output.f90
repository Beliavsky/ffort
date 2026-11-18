program main

implicit none
integer :: a(3)
call change(a)
print *,a
contains
pure subroutine change(x)
integer, intent(out) :: x(:)
x=5
end subroutine change
end program main
