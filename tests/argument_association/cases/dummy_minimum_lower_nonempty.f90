program main

implicit none
integer :: a(2)
a=3
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(inout) :: x(-2147483647-1:)
x(-2147483647-1)=4
x(-2147483647)=8
end subroutine change
end program main
