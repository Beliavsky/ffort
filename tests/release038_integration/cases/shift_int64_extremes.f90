program integration_main
use,intrinsic::iso_fortran_env,only:ik=>int64
implicit none
integer(ik)::big,small
integer::a(5),b(5)
big=huge(0_ik)
small=-big-1_ik
a=[1,2,3,4,5]
b=cshift(a,big)
if(any(b/=[3,4,5,1,2]))error stop 1
b=cshift(a,small)
if(any(b/=[3,4,5,1,2]))error stop 2
b=cshift(cshift(a,big),small)
if(any(b/=[5,1,2,3,4]))error stop 3
write(*,'(a)')'ok'
end program
