program main

implicit none
integer :: a
a=4
call change(a+3,a)
print *,a
contains
subroutine change(y,x)
integer, intent(in) :: y
integer, intent(out) :: x
x=y*2
end subroutine change
end program main
