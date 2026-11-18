program main

implicit none
integer :: a(32768)
call change(a,a)
contains
subroutine change(x,y)
integer, intent(in) :: x(:),y(:)
print *,size(x)+size(y)
end subroutine change
end program main
