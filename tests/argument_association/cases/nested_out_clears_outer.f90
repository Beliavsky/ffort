program main

implicit none
integer :: a
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(out) :: x
x=3
call next(x)
end subroutine change
subroutine next(x)
integer, intent(out) :: x
return
end subroutine next
end program main
