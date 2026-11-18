program main

implicit none
logical :: a(3)
a=.true.
call change(a)
print *,a
contains
subroutine change(x)
logical, intent(inout) :: x(:)
x=.not. x
end subroutine change
end program main
