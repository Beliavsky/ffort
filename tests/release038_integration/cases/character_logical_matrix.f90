program integration_main
use,intrinsic::iso_fortran_env,only:ik=>int64
implicit none
character(3)::a(2,3),b(2,3)
logical::m(2,3),n(2,3)
a=reshape(['a  ',' bb','ccc','dd ',' e ','fff'],[2,3])
b=cshift(dim=2,shift=[1_ik,-1_ik],array=a)
if(any(b/=reshape(['ccc','fff',' e ',' bb','a  ','dd '],[2,3])))error stop 1
m=reshape([.true.,.false.,.false.,.true.,.true.,.false.],[2,3])
n=cshift(m,shift=[1,-1],dim=2)
if(any(n.neqv.reshape([.false.,.false.,.true.,.false.,.true.,.true.],[2,3])))error stop 2
write(*,'(6(a3,"|"))')b
end program
