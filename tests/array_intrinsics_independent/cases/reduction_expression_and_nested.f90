program array_intrinsic_oracle
implicit none
integer :: aa(2,3),bb(3)
aa(:,1)=1
aa(:,2)=2
aa(:,3)=3
bb=sum(aa,1)+maxval(aa,1)
print *,bb,sum(sum(aa,1)),product(maxval(aa,2))
print *,sum(aa+1,aa>1),maxval(aa*2,2)
end program
