program main

implicit none
integer :: a(2),b(3)
a=1
b=2
call change(a,b)
print *,a,b
contains
subroutine change(x,y)
integer, intent(inout) :: x(:),y(:)
x=x+size(y)
y=y+size(x)
end subroutine change
end program main
