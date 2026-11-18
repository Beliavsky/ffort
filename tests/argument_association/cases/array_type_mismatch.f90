program main

implicit none
logical :: a(3)
print *,123
call change(a)
contains
subroutine change(x)
integer, intent(out) :: x(:)
return
end subroutine change
end program main
