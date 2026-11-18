program p
use,intrinsic::iso_fortran_env,only:dp=>real64
implicit none
integer,parameter::wp=dp
real(wp),parameter::x=2.25_wp
print *,wp,kind(x),x
end program
