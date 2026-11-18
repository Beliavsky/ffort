! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x(2,2)
real(sp)::y(2,2)
x=reshape([-2._dp,0._dp,2._dp,4._dp],[2,2])
y=cshift(aint(asinh(x),kind=sp),1,dim=2)
if(any(y/=reshape([1._sp,2._sp,-1._sp,0._sp],[2,2])))error stop 1
if(any(shape(y)/=[2,2]))error stop 2
if(minexponent(y)/=-125.or.maxexponent(x)/=1024)error stop 3
write(*,'(a)')'ok'
end program
