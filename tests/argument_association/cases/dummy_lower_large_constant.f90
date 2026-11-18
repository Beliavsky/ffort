program main

implicit none
integer :: a(2)
a=1
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(inout) :: x(200:)
x(200)=3
x(201)=5
end subroutine change
end program main
