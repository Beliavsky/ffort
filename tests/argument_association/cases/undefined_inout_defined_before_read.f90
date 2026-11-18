program main

implicit none
integer :: a
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(inout) :: x
x=8
end subroutine change
end program main
