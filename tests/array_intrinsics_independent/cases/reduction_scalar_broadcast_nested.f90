program array_intrinsic_oracle
implicit none
integer :: aa(2,3),bb(2,3)
aa(:,1)=1
aa(:,2)=2
aa(:,3)=3
bb=aa+sum(aa)+maxval(aa)
print *,bb
print *,sum(aa+sum(aa),1),product(aa+minval(aa),2)
end program
