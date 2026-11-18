program main

implicit none
integer :: a(5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
call change(a(1:6:2))
print *,a
contains
subroutine change(x)
integer, intent(inout) :: x(:)
x=x+10
end subroutine change
end program main
