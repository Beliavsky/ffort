program array_intrinsic_oracle
implicit none
integer :: aa(-2:1,4:6),bb(7:9,-1:2)
aa(-2,4)=4
aa(-1,4)=0
aa(0,4)=-5
aa(1,4)=-1
aa(-2,5)=4
aa(-1,5)=2
aa(0,5)=2
aa(1,5)=0
aa(-2,6)=4
aa(-1,6)=-1
aa(0,6)=5
aa(1,6)=-2
bb(7,-1)=-4
bb(8,-1)=4
bb(9,-1)=1
bb(7,0)=0
bb(8,0)=0
bb(9,0)=4
bb(7,1)=-1
bb(8,1)=3
bb(9,1)=3
bb(7,2)=4
bb(8,2)=-4
bb(9,2)=4
print *,matmul(aa,bb)
print *,matmul(aa(1:-2:-1,6:4:-1),bb(9:7:-1,2:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
