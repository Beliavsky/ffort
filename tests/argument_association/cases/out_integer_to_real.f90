program main

implicit none
integer :: a
print *,123
call change(a)
contains
subroutine change(x)
real, intent(out) :: x
return
end subroutine change
end program main
