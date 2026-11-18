program p
implicit none
real(8)::x(2,2,2),v(2,2)
integer(8)::d
x(:,:,1)=reshape([1.0_8,2.0_8,3.0_8,4.0_8],[2,2])
x(:,:,2)=reshape([5.0_8,6.0_8,7.0_8,8.0_8],[2,2])
d=2
v=norm2(dim=d,x=x)
if(any(abs(v-reshape(sqrt([10.0_8,20.0_8,74.0_8,100.0_8]),[2,2]))>2d-14)) error stop 1
if(abs(norm2(x)-sqrt(204.0_8))>2d-14) error stop 2
end program
