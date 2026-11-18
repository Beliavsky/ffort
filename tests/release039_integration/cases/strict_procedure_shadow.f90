! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none

if(erf(3._dp)/=13._dp)error stop 1
if(bessel_jn(2,4._dp)/=6._dp)error stop 2
if(minexponent(3._dp)/=23)error stop 3
write(*,'(a)')'ok'
contains
real(dp) function erf(x)
real(dp),intent(in)::x
erf=x+10._dp
end function
real(dp) function bessel_jn(n,x)
integer,intent(in)::n
real(dp),intent(in)::x
bessel_jn=x+n
end function
integer function minexponent(x)
real(dp),intent(in)::x
minexponent=int(x)+20
end function
end program
