program array_intrinsic_oracle
implicit none
integer :: aa(-2:1,4:7),bb(7:10,-1:0)
aa(-2,4)=-1
aa(-1,4)=1
aa(0,4)=3
aa(1,4)=-3
aa(-2,5)=-4
aa(-1,5)=2
aa(0,5)=2
aa(1,5)=-2
aa(-2,6)=1
aa(-1,6)=4
aa(0,6)=-1
aa(1,6)=5
aa(-2,7)=-2
aa(-1,7)=2
aa(0,7)=3
aa(1,7)=-1
bb(7,-1)=-4
bb(8,-1)=2
bb(9,-1)=3
bb(10,-1)=0
bb(7,0)=-1
bb(8,0)=5
bb(9,0)=-2
bb(10,0)=-5
print *,matmul(aa,bb)
print *,matmul(aa(1:-2:-1,7:4:-1),bb(10:7:-1,0:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
