program integration_main
use,intrinsic::iso_fortran_env,only:dp=>real64,i8=>int64
implicit none
real(dp)::a(0,3),b(0,3),c(2,0),d(2,0)
integer(i8)::s(3)
s=[huge(0_i8),-huge(0_i8),0_i8]
b=cshift(erfc_scaled(a),s,dim=1)
d=erfc_scaled(cshift(c,[1_i8,-1_i8],dim=2))
if(size(b)/=0.or.size(b,1)/=0.or.size(b,2)/=3)error stop 1
if(size(d)/=0.or.size(d,1)/=2.or.size(d,2)/=0)error stop 2
write(*,'(a)')'ok'
end program
