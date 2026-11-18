! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp),allocatable::x(:)
integer,allocatable::n(:)
allocate(x(2))
allocate(n(3))
x=0._dp
n=0
write(*,'(a)')'before'
write(*,*)'partial',anint(bessel_jn(n,x),sp)
end program
