program main

implicit none
integer :: a(5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
call change(a(5:1:-1))
print *,a
contains
subroutine change(x)
integer, intent(inout) :: x(:)
call next(x(2))
end subroutine change
subroutine next(y)
integer, intent(inout) :: y
y=y+20
end subroutine next
end program main
