program main

implicit none
integer :: a(5)
a=1
call change(a,a)
contains
subroutine change(x,y)
integer, intent(out) :: x(:),y(:)
return
end subroutine change
end program main
