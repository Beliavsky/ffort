program main

implicit none
integer :: a(40000)
print *,99
call change(a,a)
contains
subroutine change(x,y)
integer, intent(in) :: x(:),y(:)
return
end subroutine change
end program main
