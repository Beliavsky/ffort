program array_intrinsic_oracle
implicit none
integer :: aa(2,3),dd
logical :: mm(2,3)
aa(:,1)=1
aa(:,2)=2
aa(:,3)=3
mm=.true.
mm(:,2)=.false.
dd=1
print *,product(aa,dd),product(aa,dd,mm),size(product(aa,dd))
dd=2
print *,product(aa,dd),product(aa,dd,mm),size(product(aa,dd))
end program
