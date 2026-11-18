program array_intrinsic_oracle
implicit none
integer :: aa(-2:-1,4:6),bb(7:9,-1:1)
aa(-2,4)=-3
aa(-1,4)=-1
aa(-2,5)=-1
aa(-1,5)=-1
aa(-2,6)=-3
aa(-1,6)=-4
bb(7,-1)=4
bb(8,-1)=-5
bb(9,-1)=-4
bb(7,0)=4
bb(8,0)=-2
bb(9,0)=5
bb(7,1)=-1
bb(8,1)=-3
bb(9,1)=-5
print *,matmul(aa,bb)
print *,matmul(aa(-1:-2:-1,6:4:-1),bb(9:7:-1,1:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
