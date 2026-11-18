! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x(3),y(3)
x=[0._dp,1._dp,2._dp]
y=-9._dp
where(x>=1._dp)y=aint(acosh(x),sp)
if(any(y/=[-9._dp,0._dp,1._dp]))error stop 1
where(x>0._dp)y=anint(bessel_y0(x),dp)
if(any(y/=[-9._dp,0._dp,1._dp]))error stop 2
write(*,'(a)')'ok'
end program
