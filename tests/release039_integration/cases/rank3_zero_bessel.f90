! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x(2,2,2),t(2,2,2)
integer::n(2,2,2),i,j,k
real(sp)::y(2,2,2)
x=0._dp
n=1
n(1,1,1)=0
y=anint(bessel_jn(n,x),kind=sp)
if(y(1,1,1)/=1._sp)error stop 1
t=aint(asinh(erf(y)),kind=dp)
do k=1,2
do j=1,2
do i=1,2
if(i+j+k>3.and.y(i,j,k)/=0._sp)error stop 2
if(t(i,j,k)/=0._dp)error stop 3
end do
end do
end do
write(*,'(a)')'ok'
end program
