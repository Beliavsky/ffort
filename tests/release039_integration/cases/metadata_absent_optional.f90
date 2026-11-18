! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none

call check()
contains
subroutine check(x)
real(dp),optional,intent(in)::x(:)
if(minexponent(aint(x,sp))/=-125)error stop 1
if(maxexponent(bessel_yn(99,x))/=1024)error stop 2
end subroutine
end program
