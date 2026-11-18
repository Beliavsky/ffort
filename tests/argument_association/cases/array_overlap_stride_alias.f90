program main

implicit none
integer :: a(5)
a=1
call change(a(1:5:2),a(3:5))
contains
subroutine change(x,y)
integer, intent(out) :: x(:),y(:)
return
end subroutine change
end program main
