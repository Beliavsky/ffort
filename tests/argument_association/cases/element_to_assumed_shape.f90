program main

implicit none
integer :: a(3)
print *,123
call change(a(1))
contains
subroutine change(x)
integer, intent(inout) :: x(:)
return
end subroutine change
end program main
