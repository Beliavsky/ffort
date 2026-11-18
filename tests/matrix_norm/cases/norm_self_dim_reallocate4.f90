program p
implicit none
real(4),allocatable::x(:,:)
real(4)::v(2)
x=reshape([3.0_4,0.0_4,4.0_4,5.0_4],[2,2])
v=norm2(x,2)
if(any(v/=[5.0_4,5.0_4])) error stop 1
x=transpose(x)
if(any(norm2(x,1)/=v)) error stop 2
end program
