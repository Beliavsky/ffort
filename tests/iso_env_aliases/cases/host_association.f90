program p
use,intrinsic::iso_fortran_env,only:dp=>real64
implicit none
print *,twice(2.5_dp)
contains
pure real(dp) function twice(x) result(y)
real(dp),intent(in)::x
y=2.0_dp*x
end function
end program
