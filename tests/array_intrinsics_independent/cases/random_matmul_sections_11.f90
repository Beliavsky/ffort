program array_intrinsic_oracle
implicit none
integer :: aa(-2:1,4:7),bb(7:10,-1:2)
aa(-2,4)=2
aa(-1,4)=-1
aa(0,4)=-1
aa(1,4)=2
aa(-2,5)=-5
aa(-1,5)=-3
aa(0,5)=-4
aa(1,5)=-3
aa(-2,6)=-1
aa(-1,6)=3
aa(0,6)=5
aa(1,6)=4
aa(-2,7)=-1
aa(-1,7)=2
aa(0,7)=-4
aa(1,7)=5
bb(7,-1)=-3
bb(8,-1)=3
bb(9,-1)=-1
bb(10,-1)=1
bb(7,0)=0
bb(8,0)=-5
bb(9,0)=1
bb(10,0)=-3
bb(7,1)=0
bb(8,1)=2
bb(9,1)=-5
bb(10,1)=4
bb(7,2)=-5
bb(8,2)=-5
bb(9,2)=0
bb(10,2)=0
print *,matmul(aa,bb)
print *,matmul(aa(1:-2:-1,7:4:-1),bb(10:7:-1,2:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
