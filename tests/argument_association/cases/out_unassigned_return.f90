program main

implicit none
integer :: a
a=7
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(out) :: x
return
end subroutine change
end program main
