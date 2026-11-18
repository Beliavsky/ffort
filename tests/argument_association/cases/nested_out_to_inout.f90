program main

implicit none
integer :: a
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(out) :: x
call next(x)
end subroutine change
subroutine next(x)
integer, intent(inout) :: x
x=19
end subroutine next
end program main
