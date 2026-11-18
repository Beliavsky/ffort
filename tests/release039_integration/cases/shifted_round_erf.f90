! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x(4)
real(sp)::y(4)
x=[-1.5_dp,-0.5_dp,0.5_dp,1.5_dp]
y=cshift(anint(x,kind=sp),1_ik)
if(any(y/=[-1._sp,1._sp,2._sp,-2._sp]))error stop 1
if(any(aint(erf(y),kind=dp)/=0._dp))error stop 2
if(kind(y)/=sp.or.kind(aint(erf(y),dp))/=dp)error stop 3
write(*,'(a)')'ok'
end program
