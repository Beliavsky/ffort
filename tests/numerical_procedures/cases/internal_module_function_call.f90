module m
implicit none
integer, parameter :: dp=8
contains
real(dp) function twice(x) result(r)
real(dp), intent(in) :: x
r=x*2.0_dp
end function twice
end module m
program main
use m
implicit none

call report(2.0_dp)
contains
subroutine report(x)
real(dp), intent(in) :: x
print *,twice(x)
end subroutine report
end program main
