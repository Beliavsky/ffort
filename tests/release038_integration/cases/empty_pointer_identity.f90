program integration_main
use,intrinsic::iso_fortran_env,only:dp=>real64
implicit none
real(dp),target::a(0),b(0)
real(dp),pointer::p(:),q(:)
p=>a
q=>b
if(.not.associated(p))error stop 1
if(associated(p,a).or.associated(p,p).or.associated(p,q))error stop 2
if(size(cshift(erfc_scaled(a),1))/=0)error stop 3
write(*,'(a)')'ok'
end program
