module m
implicit none
integer, parameter :: rk=8
integer, parameter :: dp=rk
contains
real(dp) function twice(x) result(r)
real(dp), intent(in) :: x
r=x*2.0_dp
end function twice
end module m
program main
use m
implicit none

print *,twice(2.3_dp)
end program main
