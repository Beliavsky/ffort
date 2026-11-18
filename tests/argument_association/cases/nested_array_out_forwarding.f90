program main

implicit none
integer :: a(5)
a=9
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(out) :: x(:)
call next(x)
end subroutine change
subroutine next(y)
integer, intent(inout) :: y(:)
y=12
end subroutine next
end program main
