program main

implicit none
integer :: a(6)
a=0
call change(a(1:6:2),a(2:6:2))
print *,a
contains
subroutine change(x,y)
integer, intent(out) :: x(:),y(:)
x=4
y=9
end subroutine change
end program main
