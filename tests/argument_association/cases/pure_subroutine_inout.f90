program main

implicit none
integer :: a
a=4
call change(a)
print *,a
contains
pure subroutine change(x)
integer, intent(inout) :: x
x=x+1
end subroutine change
end program main
