program main

implicit none
integer :: a(6)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
a(6)=6
call change(a(1:3),a(4:6))
print *,a
contains
subroutine change(x,y)
integer, intent(in) :: x(:)
integer, intent(out) :: y(:)
y=x*2
end subroutine change
end program main
