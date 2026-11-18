module m
implicit none
integer,parameter::dp=8
contains
subroutine f(x)
real,intent(in)::x
print *,x
end subroutine f
end module m
program main
use m
implicit none

print *,777
call f(1.0_dp)
end program main
