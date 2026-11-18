program p
implicit none
real(8),allocatable::x(:,:)
real(8)::v(2)
x=reshape([3.0_8,0.0_8,4.0_8,5.0_8],[2,2])
v=norm2(x,2)
if(any(v/=[5.0_8,5.0_8])) error stop 1
x=transpose(x)
if(any(norm2(x,1)/=v)) error stop 2
end program
