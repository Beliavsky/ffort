program main

implicit none
integer :: a(3)
a=1
call change(a)
contains
subroutine change(x)
integer, intent(inout) :: x(:,:)
return
end subroutine change
end program main
