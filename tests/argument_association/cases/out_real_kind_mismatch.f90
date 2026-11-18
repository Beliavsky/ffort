program main

implicit none
real(8) :: a
print *,123
call change(a)
contains
subroutine change(x)
real, intent(out) :: x
return
end subroutine change
end program main
