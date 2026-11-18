program main

implicit none
real(8) :: a(3)
print *,123
call change(a)
contains
subroutine change(x)
real, intent(inout) :: x(:)
return
end subroutine change
end program main
