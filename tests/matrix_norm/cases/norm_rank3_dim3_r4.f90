program p
implicit none
real(4)::x(2,2,2),v(2,2)
integer(8)::d
x(:,:,1)=reshape([1.0_4,2.0_4,3.0_4,4.0_4],[2,2])
x(:,:,2)=reshape([5.0_4,6.0_4,7.0_4,8.0_4],[2,2])
d=3
v=norm2(dim=d,x=x)
if(any(abs(v-reshape(sqrt([26.0_4,40.0_4,58.0_4,80.0_4]),[2,2]))>2e-6)) error stop 1
if(abs(norm2(x)-sqrt(204.0_4))>2e-6) error stop 2
end program
