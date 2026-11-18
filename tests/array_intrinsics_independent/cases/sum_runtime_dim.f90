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
print *,sum(aa,dd),sum(aa,dd,mm),size(sum(aa,dd))
dd=2
print *,sum(aa,dd),sum(aa,dd,mm),size(sum(aa,dd))
end program
