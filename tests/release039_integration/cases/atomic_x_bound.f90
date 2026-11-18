! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x
x=1048577._dp
write(*,'(a)')'before'
write(*,*)'partial',asinh(bessel_j0(x))
end program
