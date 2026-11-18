program p
implicit none
real::x(2,2)
x=reshape([3.,0.,4.,5.],[2,2])
x(:,1)=norm2(x,dim=1)
if(any(abs(x(:,1)-[3.,sqrt(41.)])>2e-6)) error stop 1
end program
