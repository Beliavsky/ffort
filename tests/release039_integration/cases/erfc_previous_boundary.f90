! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x(3)
real(sp)::y(3)
x=[0._dp,1._dp,2._dp]
y=cshift(anint(10._dp*erfc_scaled(x),sp),1)
if(any(y/=[4._sp,3._sp,10._sp]))error stop 1
if(minexponent(y)/=-125)error stop 2
if(aint(erf(0._dp))/=0._dp)error stop 3
write(*,'(a)')'ok'
end program
