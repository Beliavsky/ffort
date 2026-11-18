program integration_main
use,intrinsic::iso_fortran_env,only:dp=>real64,ik=>int64
implicit none
real(dp),target::a(3)
real(dp)::x
real(dp),pointer::p(:)
integer(ik)::s,d
if(kind(cshift(erfc_scaled(a),s,d))/=dp)error stop 1
if(kind(associated(p,a))/=4)error stop 2
x=-huge(1._dp)
if(kind(erfc_scaled(x))/=dp)error stop 3
write(*,'(a)')'ok'
end program
