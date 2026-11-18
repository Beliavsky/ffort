program main

implicit none
integer :: a(5)
a=1
call change(a(5:1:-2),a(1:3))
contains
subroutine change(x,y)
integer, intent(out) :: x(:),y(:)
return
end subroutine change
end program main
