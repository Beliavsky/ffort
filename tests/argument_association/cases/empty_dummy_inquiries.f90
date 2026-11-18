program main

implicit none
integer :: a(2:1)
call change(a)
contains
subroutine change(x)
integer, intent(in) :: x(-3:)
print *,size(x),lbound(x,1),ubound(x,1)
end subroutine change
end program main
