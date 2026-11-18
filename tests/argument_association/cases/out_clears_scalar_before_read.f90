program main

implicit none
integer :: a
a=7
call change(a)
contains
subroutine change(x)
integer, intent(out) :: x
print *,x
end subroutine change
end program main
