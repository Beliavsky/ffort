module constants
implicit none
integer,parameter::nr=2,nc=3
integer,parameter::shape_vector(2)=[nr,nc]
integer,parameter::a(-1:0,4:6)=reshape([1,2],shape_vector,pad=[3,4],order=[2,1])
integer,parameter::sliced(2,2)=a(:,6:5:-1)
real(8),parameter::r(2,2)=reshape([1.25_8,2.5_8],[2,2],pad=[3.75_8])
logical,parameter::mask(2,2)=reshape([.true.,.false.],[2,2],pad=[.true.])
character(len=3),parameter::words(2,2)=reshape(['ab','cd'],[2,2],pad=['ef'])
integer,parameter::z(0,2)=reshape([1],[0,2],order=[2,1])
integer,parameter::zz(2,0)=reshape(z,[2,0])
end module
program p
use constants
implicit none
integer::copy(-3:-2,7:9)=reshape(a,[2,3])+10
integer(8)::wide(2,2)=reshape([10000000000_8,20000000000_8],[2,2],pad=[30000000000_8])
real::converted(2,2)=reshape([1,2,3,4],[2,2])
logical::flags(2,2)=.not.reshape([.true.,.false.,.false.,.true.],[2,2])
character(len=3)::text(2,2)=reshape(['xx','yy','zz','qq'],[2,2],order=[2,1])
print *,a,sliced,copy,r,mask,words,size(z),size(zz),wide,converted,flags,text
call local_constants()
contains
subroutine local_constants()
integer,parameter::local(2,2)=reshape([5,6,7,8],[2,2],order=[2,1])
print *,local
end subroutine
end program
