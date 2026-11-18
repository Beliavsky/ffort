program main

implicit none
integer :: a
a=4
call change(a)
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(inout) :: x
x=x*3+1
end subroutine change
end program main
