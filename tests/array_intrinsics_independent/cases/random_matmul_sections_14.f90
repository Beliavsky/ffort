program array_intrinsic_oracle
implicit none
integer :: aa(-2:0,4:7),bb(7:10,-1:2)
aa(-2,4)=-2
aa(-1,4)=0
aa(0,4)=4
aa(-2,5)=1
aa(-1,5)=2
aa(0,5)=3
aa(-2,6)=1
aa(-1,6)=2
aa(0,6)=-1
aa(-2,7)=0
aa(-1,7)=-4
aa(0,7)=0
bb(7,-1)=-4
bb(8,-1)=-5
bb(9,-1)=2
bb(10,-1)=-4
bb(7,0)=-3
bb(8,0)=1
bb(9,0)=3
bb(10,0)=1
bb(7,1)=1
bb(8,1)=0
bb(9,1)=2
bb(10,1)=5
bb(7,2)=-3
bb(8,2)=-3
bb(9,2)=2
bb(10,2)=3
print *,matmul(aa,bb)
print *,matmul(aa(0:-2:-1,7:4:-1),bb(10:7:-1,2:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
