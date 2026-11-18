program main

implicit none
real(8) :: a
call change(a)
print *,a
contains
subroutine change(x)
real(8), intent(out) :: x
x=1.000000000001_8
end subroutine change
end program main
