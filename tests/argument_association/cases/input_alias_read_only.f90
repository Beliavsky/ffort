program main

implicit none
integer :: a
a=3
call change(a,a)
contains
subroutine change(x,y)
integer, intent(in) :: x,y
print *,x+y
end subroutine change
end program main
