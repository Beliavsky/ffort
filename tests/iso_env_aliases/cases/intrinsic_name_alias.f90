program p
use,intrinsic::iso_fortran_env,only:fraction=>real64
implicit none
real(fraction)::x=2.0_fraction
print *,fraction,kind(x),x
end program
