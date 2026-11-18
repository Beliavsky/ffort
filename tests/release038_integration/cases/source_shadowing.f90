program integration_main
use,intrinsic::iso_fortran_env,only:dp=>real64
implicit none
integer::real64
real(dp)::a(3)
real64=3
a=cshift([1._dp,2._dp,3._dp],real64)
if(any(a/=[4._dp,5._dp,6._dp]))error stop 1
if(erfc_scaled(2._dp)/=12._dp)error stop 2
write(*,'(a)')'ok'
contains
function cshift(a,n) result(r)
real(dp),intent(in)::a(:)
integer,intent(in)::n
real(dp)::r(size(a))
r=a+n
end function
function erfc_scaled(x) result(r)
real(dp),intent(in)::x
real(dp)::r
r=x+10._dp
end function
end program
