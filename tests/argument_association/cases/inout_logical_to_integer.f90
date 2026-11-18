program main

implicit none
logical :: a
print *,123
call change(a)
contains
subroutine change(x)
integer, intent(inout) :: x
return
end subroutine change
end program main
