program main

implicit none
integer :: a
a=99
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(out) :: x
x=1
call next(x)
end subroutine change
subroutine next(x)
integer, intent(out) :: x
x=22
end subroutine next
end program main
