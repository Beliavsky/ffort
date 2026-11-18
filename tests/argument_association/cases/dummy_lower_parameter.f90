program main

implicit none
integer :: a(3)
call change(a)
print *,a
contains
subroutine change(x)
integer, parameter :: lo=-1
integer, intent(out) :: x(lo:)
x(-1)=3
x(0)=4
x(1)=5
end subroutine change
end program main
