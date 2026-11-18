program main

implicit none
real(8) :: a(3)
a=1.0_8
call change(a)
print *,a
contains
subroutine change(x)
real(8), intent(inout) :: x(:)
x=x+1.0e-12_8
end subroutine change
end program main
