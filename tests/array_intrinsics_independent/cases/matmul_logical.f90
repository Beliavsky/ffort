program array_intrinsic_oracle
implicit none
logical :: aa(2,3),bb(3,2)
aa=.false.
bb=.false.
aa(1,1)=.true.
aa(2,3)=.true.
bb(1,2)=.true.
bb(3,1)=.true.
print *,matmul(aa,bb),matmul(aa,bb(:,1)),matmul(aa(1,:),bb)
end program
