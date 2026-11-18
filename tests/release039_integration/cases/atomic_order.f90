! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
integer(ik)::n
n=33_ik
write(*,'(a)')'before'
write(*,*)'partial',erf(bessel_jn(n,1._dp))
end program
