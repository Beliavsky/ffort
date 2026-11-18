program main

implicit none
integer :: a(5)
a=1
call change(a,a(2))
contains
subroutine change(x,y)
integer, intent(inout) :: x(:),y
return
end subroutine change
end program main
