program integration_main
use,intrinsic::iso_fortran_env,only:i8=>int64
implicit none
integer(i8),target::a(3,2)
integer(i8),pointer::p(:)
a=reshape([1_i8,2_i8,3_i8,4_i8,5_i8,6_i8],[3,2])
p=>a(:,1)
a=cshift(a,shift=a(1,:),dim=1)
if(any(a/=reshape([2_i8,3_i8,1_i8,5_i8,6_i8,4_i8],[3,2])))error stop 1
if(.not.associated(p,a(:,1)))error stop 2
write(*,'(a)')'ok'
end program
