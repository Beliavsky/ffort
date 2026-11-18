program array_intrinsic_oracle
implicit none
integer :: aa(-2:0,4:6),bb(7:9,-1:-1)
aa(-2,4)=-4
aa(-1,4)=-4
aa(0,4)=3
aa(-2,5)=-3
aa(-1,5)=-2
aa(0,5)=-2
aa(-2,6)=1
aa(-1,6)=2
aa(0,6)=3
bb(7,-1)=-5
bb(8,-1)=-4
bb(9,-1)=1
print *,matmul(aa,bb)
print *,matmul(aa(0:-2:-1,6:4:-1),bb(9:7:-1,-1:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
