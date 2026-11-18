program main

implicit none
logical :: a
call change(a)
print *,a
contains
subroutine change(x)
logical, intent(out) :: x
x=.true.
end subroutine change
end program main
