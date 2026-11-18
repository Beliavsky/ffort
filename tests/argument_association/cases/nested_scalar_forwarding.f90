program main

implicit none
integer :: a
a=2
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(inout) :: x
call next(x)
x=x*2
end subroutine change
subroutine next(x)
integer, intent(inout) :: x
x=x+3
end subroutine next
end program main
