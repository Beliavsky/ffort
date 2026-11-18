program main

implicit none
integer :: a(3)
a=0
call change(a(1),a(3))
print *,a
contains
subroutine change(x,y)
integer, intent(out) :: x,y
x=4
y=8
end subroutine change
end program main
