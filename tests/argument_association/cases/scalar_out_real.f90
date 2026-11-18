program main

implicit none
real :: a
call change(a)
print *,a
contains
subroutine change(x)
real, intent(out) :: x
x=2.5
end subroutine change
end program main
