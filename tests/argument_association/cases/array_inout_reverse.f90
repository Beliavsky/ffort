program main

implicit none
integer :: a(-2:2)
a(-2)=1
a(-1)=2
a(0)=3
a(1)=4
a(2)=5
call change(a(2:-2:-1))
print *,a
contains
subroutine change(x)
integer, intent(inout) :: x(:)
x=x+10
end subroutine change
end program main
