module m
implicit none

contains
subroutine report(x)
real, intent(in) :: x
real :: a
a=x*2
print *,a
end subroutine report
end module m
program main
use m
implicit none

call report(1.0)
call report(2.0)
call report(1.0)
end program main
