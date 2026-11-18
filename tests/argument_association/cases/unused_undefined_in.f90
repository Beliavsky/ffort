program main

implicit none
integer :: a
call change(a)
print *,7
contains
subroutine change(x)
integer, intent(in) :: x
return
end subroutine change
end program main
