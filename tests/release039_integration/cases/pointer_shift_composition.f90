! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp),target::a(4)
real(dp),pointer::p(:),q(:)
a=[-2.5_dp,-0.5_dp,0.5_dp,2.5_dp]
p=>a(4:1:-1)
q=>a
if(associated(p,q).or..not.associated(q,a))error stop 1
q=cshift(aint(p),1_ik)
if(any(a/=[0._dp,0._dp,-2._dp,2._dp]))error stop 2
if(minexponent(erf(p))/=-1021)error stop 3
write(*,'(a)')'ok'
end program
