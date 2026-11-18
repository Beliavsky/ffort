program array_intrinsic_oracle
implicit none
integer :: aa(2,3),xx(3),yy(2)
aa(:,1)=1
aa(:,2)=2
aa(:,3)=3
xx(1)=2
xx(2)=3
xx(3)=4
yy(1)=5
yy(2)=6
print *,matmul(aa,xx),matmul(yy,aa)
print *,matmul(aa(2:1:-1,3:1:-1),xx(3:1:-1))
end program
