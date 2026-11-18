program main

implicit none
integer :: a
a=1
call change(a)
contains
subroutine change(x)
integer, intent(in), intent(out) :: x
return
end subroutine change
end program main
