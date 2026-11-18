program main

implicit none
integer :: a(-2:2)
a=9
call change(a(-1))
print *,a
contains
subroutine change(x)
integer, intent(out) :: x
x=4
end subroutine change
end program main
