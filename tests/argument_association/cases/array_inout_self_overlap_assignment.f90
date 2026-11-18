program main

implicit none
integer :: a(5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(inout) :: x(:)
x(2:5)=x(1:4)
end subroutine change
end program main
