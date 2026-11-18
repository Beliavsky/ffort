program main

implicit none
integer :: a(0)
call change(a)
print *,size(a)
contains
subroutine change(x)
integer, intent(out) :: x(:)
x=7
end subroutine change
end program main
