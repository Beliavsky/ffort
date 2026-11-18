program main

implicit none
integer :: a
a=1
call change(a)
contains
subroutine change(x)
integer, intent(in) :: x
call next(x)
end subroutine change
subroutine next(x)
integer, intent(out) :: x
x=2
end subroutine next
end program main
