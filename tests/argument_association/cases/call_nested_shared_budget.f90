program main

implicit none
integer :: a,i
a=0
print *,99
do i=1,100
call change(a)
end do
contains
subroutine change(x)
integer, intent(inout) :: x
call next(x)
end subroutine change
subroutine next(x)
integer, intent(inout) :: x
x=x+1
end subroutine next
end program main
