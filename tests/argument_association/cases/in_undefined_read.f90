program main

implicit none
integer :: a
call change(a)
contains
subroutine change(x)
integer, intent(in) :: x
print *,x
end subroutine change
end program main
