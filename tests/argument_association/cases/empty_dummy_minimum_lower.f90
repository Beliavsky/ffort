program main

implicit none
integer :: a(0)
call change(a)
contains
subroutine change(x)
integer, intent(in) :: x(-2147483647-1:)
print *,size(x),lbound(x,1),ubound(x,1)
end subroutine change
end program main
