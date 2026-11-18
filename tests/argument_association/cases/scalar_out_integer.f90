program main

implicit none
integer :: a
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(out) :: x
x=17
end subroutine change
end program main
