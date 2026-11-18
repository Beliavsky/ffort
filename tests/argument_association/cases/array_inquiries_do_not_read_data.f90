program main

implicit none
integer :: a(-2:2)
call change(a)
contains
subroutine change(x)
integer, intent(in) :: x(:)
print *,size(x),size(x,1),lbound(x,1),ubound(x,1)
end subroutine change
end program main
