program main

implicit none
real(8) :: a(5)
a=1.25_8
call change(a(5:1:-2))
print *,a
contains
subroutine change(x)
real(8), intent(inout) :: x(:)
x=x+1.0_8
end subroutine change
end program main
