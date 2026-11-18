program integration_main
use,intrinsic::iso_fortran_env,only:ik=>int64
implicit none
integer(ik),target::a(6)
integer(ik),pointer::p(:),q(:)
integer(ik)::b(3)
p=>a(1:5:2)
q=>a(5:1:-2)
if(.not.associated(target=a(1:5:2),pointer=p))error stop 1
if(associated(p,q))error stop 2
if(associated(p,a(2:6:2)))error stop 3
a=[1_ik,2_ik,3_ik,4_ik,5_ik,6_ik]
b=cshift(p,1_ik)
if(any(b/=[3_ik,5_ik,1_ik]))error stop 4
if(.not.associated(p,a(1:5:2)))error stop 5
write(*,'(a)')'ok'
end program
