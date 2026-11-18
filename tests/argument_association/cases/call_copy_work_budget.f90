program main

implicit none
integer :: a(100)
print *,99
call change(a)
contains
subroutine change(x)
integer, intent(in) :: x(:)
return
end subroutine change
end program main
