program main

implicit none
integer :: a(5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
call change(a,a(5:1:-1))
contains
subroutine change(x,y)
integer, intent(in) :: x(:),y(:)
print *,x(1),y(1)
end subroutine change
end program main
