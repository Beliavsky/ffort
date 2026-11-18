program main

implicit none
integer :: a
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(out) :: x
x=11
print *,x
end subroutine change
end program main
