program main

implicit none
integer :: a
a=0
call change(a)
contains
subroutine change(x)
integer, intent(inout) :: x
do x=1,3
call next(x)
end do
end subroutine change
subroutine next(x)
integer, intent(out) :: x
x=8
end subroutine next
end program main
