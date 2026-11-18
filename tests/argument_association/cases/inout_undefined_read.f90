program main

implicit none
integer :: a
call change(a)
contains
subroutine change(x)
integer, intent(inout) :: x
x=x+1
end subroutine change
end program main
