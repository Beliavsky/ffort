program main

implicit none
integer :: a(5)
a=3
call change(a(4:2),a(3:1))
print *,a
contains
subroutine change(x,y)
integer, intent(out) :: x(:),y(:)
x=7
y=8
end subroutine change
end program main
