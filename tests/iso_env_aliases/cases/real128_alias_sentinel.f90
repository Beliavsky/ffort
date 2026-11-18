program p
use,intrinsic::iso_fortran_env,only:qp=>real128,dp=>real64
implicit none
integer,parameter::not_available=qp
real(dp)::x=2.0_dp
print *,not_available,qp<0,kind(x),x
end program
